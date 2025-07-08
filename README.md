# MIPS32
This repository contains the implementation of a MIPS32 processor, meticulously designed and developed based on the principles outlined in the textbook "Computer Principles and Design in Verilog HDL" by Yamin Li. The project begins with a foundational understanding of MIPS32 processor features through the design of a single-cycle CPU. It then progressively enhances throughput with pipelining, expands the Instruction Set Architecture (ISA) with a floating-point unit (FPU), and culminates in a more complete CPU design incorporating caches and Translation Lookaside Buffers (TLBs). Each subproject serves as a significant milestone, providing a deep dive into understanding and building complex CPU architectures.

## single-cycle
This subproject implements a fundamental MIPS32 Single-Cycle CPU. In this architecture, each instruction completes its execution within a single clock cycle. While this design offers simplicity and ease of understanding, it is inherently less efficient for performance-critical applications compared to pipelined alternatives.

**Key Concepts:**

1. Instruction Set Architecture (ISA):  A thorough understanding of the MIPS32 ISA was developed, encompassing various operand types and a comprehensive set of instruction types, including arithmetic operations, logical operations, shift operations, memory access instructions (load/store), and control transfer (branches/jumps).

2. Addressing Modes: Detailed implementation of different MIPS32 addressing modes, such as Register Operand addressing (operands directly from registers), Immediate addressing (operand embedded in the instruction), Direct addressing (memory address specified in the instruction), Register Indirect addressing (memory address derived from a register's content), and Offset addressing (memory address calculated as the sum of an offset and a register's content).

3. Instruction Formats: Accurate handling and decoding of the MIPS32 R-format (register-type), I-format (immediate-type), and J-format (jump-type) instructions.

**Design & Implementation:**\
The CPU design is composed of essential core components.

1. ALU (Arithmetic Logic Unit): Responsible for performing all arithmetic and logical operations.

2. Register File: A collection of 32 general-purpose registers, enabling fast access to frequently used data.

3. Datapath: The interconnected functional units, including the ALU, register file, and multiplexers (MUXs), that process data based on control signals.

4. Control Unit: The combinatorial and sequential logic that generates the necessary control signals to orchestrate the operations within the datapath, ensuring correct instruction execution.

The implementation was carried out using Verilog HDL. The design and function were initially understood with reference to a dataflow model, after which the CPU was re-designed using behavioral styles. This re-design was verified against the same testbench used for the dataflow model, ensuring functional equivalence and correctness.

## pipelined
This subproject details the design and implementation of a MIPS32 Pipelined CPU. Unlike a single-cycle CPU, which completes each instruction in a full clock cycle (resulting in n * m cycles for n instructions each taking m cycles), a pipelined CPU significantly improves performance by overlapping the execution of multiple instructions. This allows the CPU to ideally produce a result in every clock cycle, achieving an execution time closer to n + m - 1 cycles for n instructions and m stages. This efficiency gain, however, introduces complexities related to managing concurrent operations.

**Pipeline Stages:**\
The execution of each instruction is systematically divided into five distinct stages, allowing for parallel processing.

1. Instruction Fetch (IF): Fetches the instruction from memory using the Program Counter (PC).
  
2. Instruction Decode (ID): Decodes the fetched instruction, reads operands from the register file, and calculates branch targets.
   
3. Execution (EXE): Performs arithmetic and logical operations using the ALU, or calculates memory addresses for load/store instructions.
   
4. Memory Access (MEM): Accesses data memory for load (read) or store (write) operations.
   
5. Write Back (WB): Writes the result of the operation back to the register file. To facilitate the overlapping of instructions, temporary results are saved in pipeline registers between each stage.

** Pipeline Hazards and Solutions:**\
Pipelining introduces challenges known as "hazards," which can prevent the next instruction in the pipeline from executing in its designated clock cycle. These hazards are addressed through specific design solutions.

1. Structural Hazards: Occur when two or more instructions attempt to use the same hardware resource simultaneously (e.g., a single memory port for both instruction fetch and data access). These are typically resolved by duplicating resources or introducing stalls.
   
2. Data Hazards: Arise from data dependencies, where an instruction needs the result of a preceding instruction that has not yet completed its write-back stage. Solutions include.
   - Forwarding (Bypassing): A critical technique where the result of an instruction is "forwarded" (or bypassed) directly from an earlier pipeline stage (e.g., EXE or MEM) to a later instruction that needs it, without waiting for the data to be written back to the register file. This significantly reduces stalls.
   - Stalling: If forwarding is not possible (e.g., a lw (load word) instruction whose result is needed immediately by the next instruction), "bubble cycles" or NOPs are inserted into the pipeline. This delays dependent instructions until the required data becomes available.

3. Control Hazards: Occur with branch or jump instructions, potentially leading to incorrect instruction fetching because the next instruction to fetch depends on the outcome of a preceding instruction that hasn't completed its execution stage. The MIPS ISA addresses this using a one-delay-slot mechanism (Delayed Branch). In this scheme, the instruction immediately following a branch or jump instruction (the "delay slot" instruction) is always executed, regardless of whether the branch is taken or not. This simplifies pipeline control at the cost of requiring the compiler to fill the delay slot with a useful instruction or a NOP.

**Implementaion:**\
The CPU is implemented in Verilog HDL, emphasizing a modular design approach. The architecture is structured into distinct Verilog files corresponding to various pipeline circuits (e.g., IF, ID, EXE, MEM, WB stages), pipeline registers (e.g., IF/ID, ID/EXE, EXE/MEM, MEM/WB registers), and comprehensive control logic that manages data flow, hazard detection, forwarding paths, and stalling mechanisms.

## pipelined_fpu
This subproject significantly extends the capabilities of the Pipelined MIPS32 CPU by integrating an IEEE 754 single-precision Floating-Point Unit (FPU). This crucial enhancement allows the CPU to perform complex floating-point arithmetic operations, which are indispensable for a wide range of modern applications, including scientific computing, graphics, and artificial intelligence.

**Floating-Point Unit (FPU) Concepts:**
1. IEEE 754 Standard: A fundamental understanding of the IEEE 754 standard for floating-point arithmetic was developed. This includes a detailed grasp of the single-precision floating-point data format, comprising the 1-bit sign (s), 8-bit exponent (e), and 23-bit significand (f) bits. The project explored the representation of various special values such as normalized and denormalized numbers, positive and negative zero, infinity, and NaN (Not a Number).
  
2. Number Conversion: Algorithms for accurate conversion between floating-point numbers and integers were implemented, carefully considering the potential for precision loss during these transformations.
  
3. FADD (Floating-Point Addition): The FPU incorporates a robust floating-point addition algorithm designed to handle IEEE 754 single-precision numbers. This process typically involves three main phases:
   - Alignment: The exponents of the two floating-point numbers are adjusted to be equal. This usually involves right-shifting the significand of the number with the smaller exponent.
   - Calculation: The significands (along with guard, round, and sticky bits for precision) are added or subtracted.
   - Normalization: The result is then normalized back into the standard 1.f x 2^exp form. This stage also handles potential overflows, underflows, and applies the appropriate rounding modes as defined by IEEE 754. Special cases such as operations involving NaN (Not a Number) or infinity are also managed.

4. FMUL (Floating-point Multiplication): The design includes a specialized floating-point multiplier for efficient execution of multiplication operations. The implementation explored a pipelined Wallace tree FMUL, which breaks down the multiplication process into several stages:
   - Partial Product Generation: Generates individual products of bits.
   - Addition: Utilizes a Wallace tree or similar structure to sum the partial products quickly.
   - Normalization: The final product is normalized, and the exponent is adjusted accordingly. This design effectively handles both normalized and denormalized numbers, producing accurate IEEE 754-compliant results.
 
5. FDIV (Floating-point Division): Floating-point division is a more complex and typically iterative operation. In this pipelined CPU with FPU, FDIV operations are identified as a source of pipeline stalls. This is primarily because division, especially when implemented without dedicated hardware dividers, often relies on iterative numerical methods, such as Newton-Raphson iterations, which require multiple cycles to converge on a result. These multi-cycle operations necessitate pipeline stall logic to ensure data dependencies are met and correct results are produced.

6. FSQRT (Floating-point Square Root): Similar to division, floating-point square root operations are also computationally intensive and iterative. The FSQRT implementation similarly causes pipeline stalls within the CPU. This is due to its reliance on iterative approximation algorithms, such as Newton-Raphson iterations, which consume multiple clock cycles. The pipeline's stall mechanism is activated to pause subsequent instructions until the square root calculation is complete and the result is available.

**Integration and Hazards:**
1. ISA Extension: The MIPS32 Instruction Set Architecture (ISA) was extended to incorporate new floating-point instructions, enabling seamless interaction between the CPU's integer pipeline and the newly integrated FPU.
2. Modular Design: Pipelined FPU modules were designed independently and then carefully integrated into the existing MIPS32 CPU pipeline. This modularity facilitates easier verification and future enhancements.
3. Pipeline Stall Handling: Special attention was given to managing pipeline stalls caused by the iterative and multi-cycle nature of complex FPU operations like division and square root. Furthermore, potential data dependencies between integer and floating-point operations (e.g., lw (load word), lwc1 (load word to coprocessor 1), swc1 (store word from coprocessor 1), and general floating-point (fp) operations) were meticulously analyzed, and appropriate stall logic was implemented to ensure correct data integrity and execution order.

## pipelined_fpu_cache_tlb
This subproject focuses on integrating sophisticated memory management components, cache memory and a Translation Lookaside Buffer (TLB), into the Pipelined MIPS32 CPU. This integration simulates a hierarchical memory system and a virtual memory environment, which are critical for significantly improving memory access performance, enabling multitasking, and enhancing system security.

**Memory Hierachy Concepts:**
1. Memory levels: Exploration of different memory levels, including registers, instruction/data caches, and the physical memory divided into 4 segments.

2. Cache memory:
   - Purpose: Caches serve as high-speed buffers for frequently accessed data, dramatically reducing the average memory access time. Their effectiveness is rooted in the principles of temporal locality (recently accessed data is likely to be accessed again soon) and spatial locality (data near recently accessed data is likely to be accessed soon).
   - Mapping Schemes: Understanding and potential implementation of Direct Mapping, Fully Associative Mapping, and Set Associative Mapping.
   - Replacement Algorithms: When a cache is full, a block must be evicted to make space for a new one. Common algorithms explored include: LRU (Least Recently Used), Random, and FIFO (First-In, First-Out).
   - Write policies: These policies determine how data written to the cache is eventually updated in main memory:
     1. Write-Through: Data is written simultaneously to both the cache and main memory.
     2. Write-Back: Data is written only to the cache initially, and updated main memory when the block is evicted.
     3. Write-Allocate: A cache miss on a write operation causes the block to be loaded into the cache first.
     4. No Write-Allocate: A cache miss on a write operation causes the data to be written directly to main memory without loading the block into the cache.

**Virtual Memory System**
1. Concepts: Virtual memory is a memory management technique that allows processes to use a logical address space that can be much larger than the physical memory available. A Memory Management Unit (MMU) is a hardware component responsible for translating these virtual addresses used by the CPU into physical addresses in main memory. This abstraction provides memory protection, enables efficient multi-tasking, and allows programs to run even if only parts of them are in physical memory.
  
2. Management schemes:
   - Segmentation: Divides a program's memory into variable-sized logical segments (e.g., code, data, stack), often based on program structure.
   - Paging: Divides both virtual and real memory into fixed-sized blocks called "pages" and "frames," respectively. Address translation occurs by mapping virtual pages to physical frames using a page table. The project considered the use of two-level page tables for improved efficiency in managing large virtual address spaces.
  
**Translation Lookaside Buffer (TLB)**
1. Functionality: The TLB is a high-speed hardware cache specifically designed to accelerate the virtual-to-physical address translation process performed by the MMU. By storing recent virtual-to-physical address mappings, it avoids redundant page table lookups, significantly reducing memory access latency for virtual memory systems.

2. CAM (Content Addressable Memory): The TLB leverages Content Addressable Memory (CAM) technology. Unlike traditional RAM, CAM allows the TLB to quickly search its entire memory in parallel using the Virtual Page Number (VPN) as the search key, directly returning the corresponding Real Page Number (RPN) if a match is found.
  
3. MIPS TLB Implementation:
    - Privilege Modes: The MIPS CPU operates in distinct privilege modes:
      1. User Mode: Restricted access, typically able to access 2GB of virtual memory and general-purpose/floating-point registers.
      2. Kernel Mode: Full system access, able to access the entire 4GB virtual address space, all register files (including CP0 registers for system control), and execute privileged instructions.
    - TLB Organization: Each entry in the TLB is structured to store critical translation information, including an 8-bit Address Space Identifier (ASID) to differentiate between processes, VPN2 (Virtual Page Number), G (Global bit), Mask (page size mask), Entry0 and Entry1 (Physical Frame Numbers for even/odd pages), PFN (Physical Frame Number), C (Cacheability), D (Dirty bit), and V (Valid bit).
    - Software Management: The MIPS TLB is unique in that it is software-managed. This means the operating system is responsible for handling TLB misses and filling TLB entries using specific MIPS instructions:
       1. tlbp: Probes the TLB to check if a specific virtual address translation exists.
       2. tlbr: Reads the contents of a TLB entry from a specified index into CPU registers.
       3. tlbwi: Writes a specific TLB entry from CPU registers to a specified index.
       4. tlbwr: Writes a random TLB entry from CPU registers to a randomly chosen index, typically used for TLB refills.
