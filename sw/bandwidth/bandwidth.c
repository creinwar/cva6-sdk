// Copyright 2024 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Christopher Reinwardt <creinwar@iis.ee.ethz.ch>


#ifndef __CHESHIRE__

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#else

#include "printf.h"
#include "regs/cheshire.h"
#include "dif/clint.h"
#include "dif/uart.h"
#include "params.h"
#include "util.h"
#include "printf.h"

extern uint64_t random(void);

#endif

#ifdef __CHESHIRE__

// Taylored for Cheshire:
//   - D-Cache: 32 KiB
//   - LLC    : 128 KiB
//   - DRAM   : >= 8 MiB
#define BUFSIZE (512*1024UL)

#else

#define BUFSIZE (128*1024*1024UL)

#endif

#define TEST_ITERS 1000UL
#define MAX_NUM_CHUNKS 16384UL

#ifdef __riscv

#define read_csr(reg) ({ \
    uint64_t __tmp; \
    __asm volatile (\
      "csrr %0, " #reg \
      : "=r"(__tmp)\
      ::\
      ); \
    __tmp;\
  })

#define fence() __asm volatile ("fence" ::: "memory");

#if (__riscv_xlen == 64)

#define read_cycle() ({ \
    uint64_t __tmp; \
    __asm volatile (\
      "csrrs %0, cycle, x0\n" \
      : "=r"(__tmp)\
      ::\
      ); \
    __tmp;\
  })

#else

#define read_cycle() ({ \
    uint64_t __tmp;
    uint32_t __hi = 0, __lo = 0;\
    __asm volatile (\
      "csrrs %0, cycleh, x0\n \
       csrrs %1, cycle, x0\n" \
      : "=r"(__hi), "=r"(__lo)\
      ::\
      ); \
    __tmp = ((uint64_t) __hi) << 32UL | __lo;\
    __tmp;
  })

#endif
#endif

#ifdef __x86_64

#define read_cycle() ({ \
    uint64_t __tmp;\
    uint32_t __hi = 0, __lo = 0;\
    __asm volatile (\
      "rdtsc\n"\
      : "=a"(__lo), "=d"(__hi)\
      ::\
    );\
    __tmp = ((uint64_t) __hi) << 32UL | __lo;\
    __tmp;\
  })

#define fence() __asm volatile ("mfence" ::: "memory");

#endif

extern void asm_stream_read(volatile void *buf, uint64_t size, uint64_t iters);
extern void asm_stream_write(volatile void *buf, uint64_t size, uint64_t iters);

extern void asm_stride_read(volatile void *buf, uint64_t num_accesses, uint64_t stride, uint64_t iters);
extern void asm_stride_write(volatile void *buf, uint64_t num_accesses, uint64_t stride, uint64_t iters);

extern void asm_random_read(volatile void *buf, uint64_t size, uint64_t iters);
extern void asm_random_write(volatile void *buf, uint64_t size, uint64_t iters);


// Make sure to place all the big buffers in the bulk section for Cheshire
#ifdef __CHESHIRE__

volatile char     __attribute__((section(".bulk")))  buffer[BUFSIZE] = {0};
volatile uint64_t __attribute__((section(".bulk"))) *rd_chunks[MAX_NUM_CHUNKS] = {0};
volatile uint64_t __attribute__((section(".bulk"))) *wr_chunks[MAX_NUM_CHUNKS] = {0};

#else

volatile char      buffer[BUFSIZE] = {0};
volatile uint64_t *rd_chunks[MAX_NUM_CHUNKS] = {0};
volatile uint64_t *wr_chunks[MAX_NUM_CHUNKS] = {0};

#endif


// Tests we want to run
//   - Streaming reads/rites
//   - Strided reads/writes
//   - Random reads/writes

// In order read/write test
// Size must be an integer multiple of 256 bytes
void test_stream_rw(volatile void *buf, uint64_t size)
{
  volatile uint64_t rd_pre = 0, rd_post = 0;
  volatile uint64_t wr_pre = 0, wr_post = 0;

  fence();
  // Test streaming writes using the assembly implementation
  wr_pre = read_cycle();
  asm_stream_write(buf, size, TEST_ITERS);
  wr_post = read_cycle();

  fence();
  // Test streaming reads using the assembly implementation
  rd_pre = read_cycle();
  asm_stream_read(buf, size, TEST_ITERS);
  rd_post = read_cycle();

  // Report average streaming read and write performance
  printf("stream,%lu,%lu,%lu,%lu,%lu\r\n", TEST_ITERS, size/8, 8UL, (uint64_t)((rd_post - rd_pre)/TEST_ITERS), (uint64_t)((wr_post - wr_pre)/TEST_ITERS));
}

// Strided read/write test
// Num accesses must be an integer multiple of 8
// Access granularity is 64 bit or 8 bytes, ensure that num_accesses*8*stride <= sizeof(buf)
void test_stride_rw(volatile void *buf, uint64_t num_accesses, uint64_t stride)
{
  volatile uint64_t rd_pre = 0, rd_post = 0;
  volatile uint64_t wr_pre = 0, wr_post = 0;

  fence();
  // Test strided writes using the assembly implementation
  wr_pre = read_cycle();
  asm_stride_write(buf, num_accesses/8, stride*sizeof(uint64_t), TEST_ITERS);
  wr_post = read_cycle();

  fence();
  // Test strided reads using the assembly implementation
  rd_pre = read_cycle();
  asm_stride_read(buf, num_accesses/8, stride*sizeof(uint64_t), TEST_ITERS);
  rd_post = read_cycle();

  // Report average strided read and write performance
  printf("stride,%lu,%lu,%lu,%lu,%lu\r\n", TEST_ITERS, num_accesses/8, stride*8, (uint64_t)((rd_post - rd_pre)/TEST_ITERS), (uint64_t)((wr_post - wr_pre)/TEST_ITERS));
}

// In order read/write test
// Size must be an integer multiple of 256 bytes
void test_random_rw(volatile void *buf, uint64_t size)
{
  volatile uint64_t rd_pre = 0, rd_post = 0;
  volatile uint64_t wr_pre = 0, wr_post = 0;

  uint64_t num_chunks = size/256;

  if(num_chunks > MAX_NUM_CHUNKS){
    printf("Error: Too many chunks to track (%lu but maximum is %lu)\r\n", num_chunks, MAX_NUM_CHUNKS);
    return;
  }

  if(num_chunks * 256 > BUFSIZE){
    printf("Error: Too many chunks for the buffer (%lu chunks of 256 bytes each = 0x%lx bytes, buffer size = 0x%lx bytes)!\r\n",
            num_chunks, num_chunks*256, BUFSIZE);
    return;
  }

  for(uint64_t i = 0; i < num_chunks; i++){
    uint64_t rd_pos = random() % num_chunks;
    uint64_t wr_pos = random() % num_chunks;

    rd_chunks[i] = (uint64_t *)(buf + 256*rd_pos);
    wr_chunks[i] = (uint64_t *)(buf + 256*wr_pos);
  }

  fence();

  // Test random writes using the assembly implementation
  wr_pre = read_cycle();
  asm_random_write(wr_chunks, num_chunks, TEST_ITERS);
  wr_post = read_cycle();

  fence();
  // Test random reads using the assembly implementation
  rd_pre = read_cycle();
  asm_random_read(rd_chunks, num_chunks, TEST_ITERS);
  rd_post = read_cycle();

  // Report average streaming read and write performance
  printf("random,%lu,%lu,%lu,%lu,%lu\r\n", TEST_ITERS, size/8, 8UL, (uint64_t)((rd_post - rd_pre)/TEST_ITERS), (uint64_t)((wr_post - wr_pre)/TEST_ITERS));
}

int main()
{

  // Cheshire only UART setup
#ifdef __CHESHIRE__
  uint32_t rtc_freq = *reg32(&__base_regs, CHESHIRE_RTC_FREQ_REG_OFFSET);
  uint64_t reset_freq = clint_get_core_freq(rtc_freq, 2500);
  uart_init(&__base_uart, reset_freq, 115200);
#endif

  // Touch the entire memory once so Linux maps pages for it
  uint64_t *bufptr = (uint64_t *) buffer;
  for(uint64_t i = 0; i < BUFSIZE/sizeof(uint64_t); i++){
    bufptr[i] = 0xDEADBEEFBEEFDEADUL;
  }

  uint64_t transfer = 256, prev_transfer = 0;

  printf("test_name,test_iterations,number_of_accesses,stride,read_cycles,write_cycles\r\n");

  fence();

  while(transfer <= BUFSIZE){

    if(transfer-prev_transfer >= 8*256){
      test_stream_rw(buffer, prev_transfer + 1*((transfer-prev_transfer)/8));
      test_stream_rw(buffer, prev_transfer + 2*((transfer-prev_transfer)/8));
      test_stream_rw(buffer, prev_transfer + 3*((transfer-prev_transfer)/8));
      test_stream_rw(buffer, prev_transfer + 4*((transfer-prev_transfer)/8));
      test_stream_rw(buffer, prev_transfer + 5*((transfer-prev_transfer)/8));
      test_stream_rw(buffer, prev_transfer + 6*((transfer-prev_transfer)/8));
      test_stream_rw(buffer, prev_transfer + 7*((transfer-prev_transfer)/8));
      test_stream_rw(buffer, transfer);
    } else if(transfer-prev_transfer >= 4*256){
      test_stream_rw(buffer, prev_transfer + 1*((transfer-prev_transfer)/4));
      test_stream_rw(buffer, prev_transfer + 2*((transfer-prev_transfer)/4));
      test_stream_rw(buffer, prev_transfer + 3*((transfer-prev_transfer)/4));
      test_stream_rw(buffer, transfer);
    } else if(transfer-prev_transfer >= 2*256){
      test_stream_rw(buffer, prev_transfer + 1*((transfer-prev_transfer)/2));
      test_stream_rw(buffer, transfer);
    } else {
      test_stream_rw(buffer, transfer);
    }

    prev_transfer = transfer;
    transfer <<= 1;
  }
  
  prev_transfer = 0;
  transfer = 256;

  fence();

  while((transfer >> 8) <= MAX_NUM_CHUNKS && transfer <= BUFSIZE){
    if(transfer-prev_transfer >= 8*256){
      test_random_rw(buffer, prev_transfer + 1*((transfer-prev_transfer)/8));
      test_random_rw(buffer, prev_transfer + 2*((transfer-prev_transfer)/8));
      test_random_rw(buffer, prev_transfer + 3*((transfer-prev_transfer)/8));
      test_random_rw(buffer, prev_transfer + 4*((transfer-prev_transfer)/8));
      test_random_rw(buffer, prev_transfer + 5*((transfer-prev_transfer)/8));
      test_random_rw(buffer, prev_transfer + 6*((transfer-prev_transfer)/8));
      test_random_rw(buffer, prev_transfer + 7*((transfer-prev_transfer)/8));
      test_random_rw(buffer, transfer);
    } else if(transfer-prev_transfer >= 4*256){
      test_random_rw(buffer, prev_transfer + 1*((transfer-prev_transfer)/4));
      test_random_rw(buffer, prev_transfer + 2*((transfer-prev_transfer)/4));
      test_random_rw(buffer, prev_transfer + 3*((transfer-prev_transfer)/4));
      test_random_rw(buffer, transfer);
    } else if(transfer-prev_transfer >= 2*256){
      test_random_rw(buffer, prev_transfer + 1*((transfer-prev_transfer)/2));
      test_random_rw(buffer, transfer);
    } else {
      test_random_rw(buffer, transfer);
    }

    prev_transfer = transfer;
    transfer <<= 1;
  }

  transfer = 64;

  fence();

  while(transfer <= BUFSIZE){
    uint32_t stride = 1;
    while((transfer >> 3)/stride >= 8 && stride <= 8){
      test_stride_rw(buffer, transfer/(8*stride), stride);
      stride <<= 1;
    }
    transfer <<= 1;
  }


  printf("Done!\r\n");

  return 0;
}
