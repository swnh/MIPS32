# MIPS32
This repository contains the implementation of a MIPS32 processor, meticulously designed and developed based on the principles outlined in the textbook "Computer Principles and Design in Verilog HDL" by Yamin Li. The project begins with a foundational understanding of MIPS32 processor features through the design of a single-cycle CPU. It then progressively enhances throughput with pipelining, expands the Instruction Set Architecture (ISA) with a floating-point unit (FPU), and culminates in a more complete CPU design incorporating caches and Translation Lookaside Buffers (TLBs). Each subproject serves as a significant milestone, providing a deep dive into understanding and building complex CPU architectures.

## single-cycle
This subproject implements a fundamental MIPS32 Single-Cycle CPU. In this architecture, each instruction completes its execution within a single clock cycle. While this design offers simplicity and ease of understanding, it is inherently less efficient for performance-critical applications compared to pipelined alternatives.

Key Concepts:

1. Instruction Set Architecture (ISA):  A thorough understanding of the MIPS32 ISA was developed, encompassing various operand types and a comprehensive set of instruction types, including arithmetic operations, logical operations, shift operations, memory access instructions (load/store), and control transfer (branches/jumps).

2. Addressing Modes: Detailed implementation of different MIPS32 addressing modes, such as Register Operand addressing (operands directly from registers), Immediate addressing (operand embedded in the instruction), Direct addressing (memory address specified in the instruction), Register Indirect addressing (memory address derived from a register's content), and Offset addressing (memory address calculated as the sum of an offset and a register's content).

3. Instruction Formats: Accurate handling and decoding of the MIPS32 R-format (register-type), I-format (immediate-type), and J-format (jump-type) instructions.
