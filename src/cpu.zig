const std = @import("std");
const Registers = @import("memory.zig").Registers;

pub const Cpu = struct {
    memory: [0x10000]u8, // 64KB of memory
    registers: Registers,
    interrupts_enabled: bool = false,
    // Add other CPU state variables here (e.g., interrupt flags, etc.)

    pub fn init() Cpu {
        return Cpu{
            .memory = undefined,
            .registers = Registers{
                .a = 0, // General purpose registers
                .b = 0, // General purpose registers
                .c = 0, // General purpose registers
                .d = 0, // General purpose registers
                .e = 0, // General purpose registers
                .h = 0, // General purpose registers
                .l = 0, // General purpose registers
                .f = 0, // Flag register
                .pc = 0x0100, // Program starts at 0x0100
                .sp = 0xFFFE, // Stack Pointer
                .hl = 0xFFFF, // HL register pair initialized to 0xFFFF
                .de = 0xFFFF, // DE register pair initialized to 0xFFFF
            },
        };
    }

    pub fn load_rom(self: *Cpu, rom: []const u8) void {
        for (rom, 0..) |byte, i| {
            if (i < self.memory.len) {
                self.memory[i] = byte;
            }
        }
    }

    fn read_memory(self: *Cpu, address: u16) u8 {
        return self.memory[address];
    }

    pub fn run(self: *Cpu) void {
        while (true) {
            const opcode = self.read_memory(self.registers.pc);
            self.registers.pc += 1;
            self.execute_opcode(opcode);
        }
    }

    pub fn push_stack(self: *Cpu, value: u16) void {
        // Decrement the stack pointer to point to the next available stack slot
        self.registers.sp -= 2;

        // Write the high byte of the value to memory at the current stack pointer
        self.memory[self.registers.sp] = @as(u8, @intCast(value >> 8)); // High byte

        // Write the low byte of the value to memory at the next stack location
        self.memory[self.registers.sp + 1] = @as(u8, @intCast(value & 0xFF)); // Low byte
    }

    fn execute_opcode(self: *Cpu, opcode: u8) void {
        switch (opcode) {
            0x00 => {}, // NOP
            0xC3 => { // JP nn
                const low = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                const high = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                const address = (@as(u16, high) << 8) | low;
                self.registers.pc = address;
            },
            0x3E => { // LD A, d8
                const value = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                self.registers.a = value;
            },
            0x05 => { // DEC B
                self.registers.b -%= 1;
                // Later you will handle flags (Z, N, H)
            },
            0x06 => { // LD B, d8
                const value = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                self.registers.b = value;
            },
            0x0E => { // LD C, d8
                const value = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                self.registers.c = value;
            },
            0x08 => { // LD (a16), SP
                const low = self.read_memory(self.registers.pc);
                const high = self.read_memory(self.registers.pc + 1);
                self.registers.pc += 2;

                const addr = (@as(u16, high) << 8) | low;

                const sp = self.registers.sp;

                // Write SP into memory at addr (little endian)
                self.memory[addr] = @intCast(sp & 0xFF); // low byte
                self.memory[addr + 1] = @intCast((sp >> 8) & 0xFF); // high byte
            },
            0x10 => { // STOP
                // No operation for STOP, this is a halt opcode
                // You can add your own logic if you need to stop the emulator or handle it differently
                std.debug.print("STOP encountered\n", .{});
            },
            0x11 => { // LD DE, d16
                const low = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                const high = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                self.registers.d = high;
                self.registers.e = low;
            },
            0x12 => { // LD (DE), A
                const address = (@as(u16, self.registers.d) << 8) | self.registers.e;
                self.memory[address] = self.registers.a;
            },
            0x13 => { // INC DE
                var de = (@as(u16, self.registers.d) << 8) | self.registers.e;
                de +%= 1;
                self.registers.d = @truncate(de >> 8);
                self.registers.e = @truncate(de);
            },
            0x14 => { // INC D
                self.registers.d += 1;
                // Handle flags (Z, N, H) later if needed
            },
            // 0x15 => { // DEC D
            //     self.registers.d -= 1;
            //     // Handle flags (Z, N, H) later if needed
            // },
            0x15 => { // DEC D
                if (self.registers.d == 0) {
                    // Set the N flag (because it's a subtraction)
                    self.registers.f |= 0x40;
                } else {
                    // If not 0, simply decrement D.
                    self.registers.d -= 1;
                }
                // Handle other flags like Z and H later if needed
            },
            0x16 => { // LD D, d8
                const value = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                self.registers.d = value;
            },
            0x17 => { // RLA
                const old_carry = (self.registers.f & 0x10) >> 4;
                self.registers.a = (self.registers.a << 1) | old_carry;
                // const new_carry = (self.registers.a & 0x80) >> 7;
                // update carry flag (optional now)
            },
            0x18 => { // JR r8
                const offset = @as(u8, self.read_memory(self.registers.pc));
                self.registers.pc += 1;
                self.registers.pc += @as(u8, offset); // Use signed byte offset
            },
            0x19 => { // ADD HL, DE
                const hl = self.registers.hl;
                const de = self.registers.de;
                const result = hl +% de; // Wrapping addition

                self.registers.hl = result;

                // Flags:
                // Zero flag: Unaffected! (do NOT set or reset it)
                self.registers.set_negative_flag(false); // Clear N flag
                self.registers.set_half_carry_flag((hl & 0x0FFF) + (de & 0x0FFF) > 0x0FFF); // Half-carry if carry from bit 11
                self.registers.set_carry_flag(@as(u32, hl) + @as(u32, de) > 0xFFFF); // Carry if carry from bit 15
            },
            0x20 => { // JR NZ, r8
                const offset = @as(u16, @bitCast(@as(u16, self.read_memory(self.registers.pc))));
                self.registers.pc +%= 1;
                if (self.registers.f & 0x80 == 0) { // Z flag not set
                    self.registers.pc +%= @as(u16, offset);
                }
            },
            0x21 => { // LD HL, d16
                const low = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                const high = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                self.registers.h = high;
                self.registers.l = low;
            },
            0x25 => { // DEC H
                self.registers.h -= 1;
                // You can later handle flags (Z, N, H) here if needed
            },
            0x26 => { // LD H, d8
                const value = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                self.registers.h = value;
            },
            0x1A => { // LD A, (DE)
                const address = (@as(u16, self.registers.d) << 8) | self.registers.e;
                self.registers.a = self.read_memory(address);
            },
            0x1C => { // INC E
                self.registers.e += 1;
                // Handle flags (Z, N, H) later if needed
            },
            0x1D => { // DEC E
                self.registers.e -= 1;
                // Handle flags (Z, N, H) later if needed
            },
            0x1F => { // RRA
                const old_carry = (self.registers.f & 0x10) << 3;
                self.registers.a = (self.registers.a >> 1) | old_carry;
                // const new_carry = self.registers.a & 0x01;
                // update carry flag (optional now)
            },
            0x2A => { // LD A, (HL+)
                const address = (@as(u16, self.registers.h) << 8) | self.registers.l;
                self.registers.a = self.memory[address];
                const new_hl = address + 1;
                self.registers.h = @truncate(new_hl >> 8);
                self.registers.l = @truncate(new_hl);
            },
            0x2C => { // INC L
                self.registers.l += 1;
                // You can later handle flags (Z, N, H) here if needed
            },
            0x2D => { // DEC L
                self.registers.l -= 1;
                // You can later handle flags (Z, N, H) here if needed
            },
            0xD2 => { // JP NC, a16
                const low = self.read_memory(self.registers.pc);
                const high = self.read_memory(self.registers.pc + 1);
                const addr = (@as(u16, high) << 8) | low;
                self.registers.pc += 2;

                if (!self.registers.get_carry_flag()) {
                    self.registers.pc = addr;
                }
            },
            0x0D => { // DEC C
                const old_c = self.registers.c;
                self.registers.c = self.registers.c - 1;

                // Set flags
                self.registers.set_zero_flag(self.registers.c == 0);
                self.registers.set_negative_flag(true);
                self.registers.set_half_carry_flag((old_c & 0x0F) == 0);
                // Carry flag is NOT changed
            },
            0x41 => { // LD B, C
                self.registers.b = self.registers.c;
            },
            0x69 => { // LD L, C
                self.registers.l = self.registers.c;
            },
            0x1E => { // LD E, (HL)
                self.registers.e = self.read_memory(self.registers.hl);
            },
            0x03 => { // INC BC
                // Increment the value of B and C as a 16-bit pair
                const bc = @as(u16, self.registers.b) << 8 | @as(u16, self.registers.c);
                const incremented_bc = bc + 1;

                // Extract the new B and C values
                self.registers.b = @intCast((incremented_bc >> 8) & 0xFF);
                self.registers.c = @intCast(incremented_bc & 0xFF);
            },
            0x67 => { // LD H, A
                self.registers.h = self.registers.a;
            },
            0xFC => { // LD A, (nn)
                const low_byte = self.read_memory(self.registers.pc + 1);
                const high_byte = self.read_memory(self.registers.pc + 2);
                const address = @as(u16, high_byte) << 8 | @as(u16, low_byte); // Corrected with @as(u16)

                // Load the value from the memory address into register A
                self.registers.a = self.read_memory(address);

                // Increment the program counter by 3 (to account for the instruction and its address bytes)
                self.registers.pc += 3;
            },
            0xC7 => { // RST 00H
                // Push the current PC value to the stack
                self.push_stack(self.registers.pc);

                // Jump to the restart address 0x00
                self.registers.pc = 0x00;
            },
            0x93 => { // SUB E
                const result = self.registers.a -% self.registers.e;

                // Set the A register to the result
                self.registers.a = result;

                // Set the flags
                self.registers.set_zero_flag(self.registers.a == 0); // Zero flag
                self.registers.set_negative_flag(true); // Negative flag
                self.registers.set_half_carry_flag((self.registers.a & 0xF) < (self.registers.e & 0xF)); // Half carry
                self.registers.set_carry_flag(result > 0xFF); // Carry flag
            },
            0x8A => { // ADC A, D
                const a = self.registers.a;
                const d = self.registers.d;
                const carry: u8 = if (self.registers.get_carry_flag()) 1 else 0;

                const result = @as(u16, a) + @as(u16, d) + carry;
                self.registers.a = @intCast(result & 0xFF);

                // Set flags
                self.registers.set_zero_flag(self.registers.a == 0);
                self.registers.set_negative_flag(false);
                self.registers.set_half_carry_flag(((a & 0xF) + (d & 0xF) + carry) > 0xF);
                self.registers.set_carry_flag(result > 0xFF);
            },
            0x32 => { // LD (HL-), A
                const address = (@as(u16, self.registers.h) << 8) | self.registers.l;
                self.memory[address] = self.registers.a;

                const new_hl = address - 1;
                self.registers.h = @truncate(new_hl >> 8);
                self.registers.l = @truncate(new_hl);
            },
            0xAF => { // XOR A
                self.registers.a ^= self.registers.a;
            },
            0xC9 => { // RET
                const low = self.read_memory(self.registers.sp);
                self.registers.sp += 1;
                const high = self.read_memory(self.registers.sp);
                self.registers.sp += 1;
                const address = (@as(u16, high) << 8) | low;
                self.registers.pc = address;
            },
            0xCD => { // CALL nn
                const low = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                const high = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                const address = (@as(u16, high) << 8) | low;

                self.registers.sp -= 2;
                const sp = self.registers.sp;
                self.memory[sp] = @truncate(self.registers.pc >> 8);
                self.memory[sp + 1] = @truncate(self.registers.pc);

                self.registers.pc = address;
            },
            0x04 => { // INC B
                self.registers.b += 1;
            },
            0x0C => { // INC C
                self.registers.c += 1;
            },
            0x01 => { // LD BC, d16
                const low = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                const high = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                self.registers.b = high;
                self.registers.c = low;
            },
            0x31 => { // LD SP, d16
                const low = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                const high = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                self.registers.sp = (@as(u16, high) << 8) | low;
            },
            0x23 => { // INC HL
                var hl = (@as(u16, self.registers.h) << 8) | self.registers.l;
                hl +%= 1;
                self.registers.h = @truncate(hl >> 8);
                self.registers.l = @truncate(hl);
            },
            0x0A => { // LD A, (BC)
                const address = (@as(u16, self.registers.b) << 8) | self.registers.c;
                self.registers.a = self.read_memory(address);
            },
            0x22 => { // LD (HL+), A
                const address = (@as(u16, self.registers.h) << 8) | self.registers.l;
                self.memory[address] = self.registers.a;
                const new_hl = address + 1;
                self.registers.h = @truncate(new_hl >> 8);
                self.registers.l = @truncate(new_hl);
            },
            0x77 => { // LD (HL), A
                const address = (@as(u16, self.registers.h) << 8) | self.registers.l;
                self.memory[address] = self.registers.a;
            },
            0x7E => { // LD A, (HL)
                const address = (@as(u16, self.registers.h) << 8) | self.registers.l;
                self.registers.a = self.read_memory(address);
            },
            0xE0 => { // LDH (n), A
                const address = 0xFF00 + @as(u16, self.read_memory(self.registers.pc));
                // const address = 0xFF00 + self.read_memory(self.registers.pc);

                self.registers.pc += 1;
                self.memory[address] = self.registers.a;
            },
            0xE2 => { // LD (C), A
                const address = 0xFF00 + @as(u16, self.registers.c);
                // const address = 0xFF00 + self.registers.c;
                self.memory[address] = self.registers.a;
            },
            0xF0 => { // LDH A, (n)
                const address = 0xFF00 + @as(u16, self.read_memory(self.registers.pc));
                // const address = 0xFF00 + self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                self.registers.a = self.read_memory(address);
            },
            0xF3 => { // DI (disable interrupts)
                self.interrupts_enabled = false;
            },
            0xFB => { // EI (enable interrupts)
                self.interrupts_enabled = true;
            },
            0xFE => { // CP d8
                const value = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                _ = self.registers.a -% value;
                // Flags update would go here later
            },
            0xEA => { // LD (nn), A
                const low = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                const high = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                const address = (@as(u16, high) << 8) | low;
                self.memory[address] = self.registers.a;
            },
            0xFA => { // LD A, (nn)
                const low = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                const high = self.read_memory(self.registers.pc);
                self.registers.pc += 1;
                const address = (@as(u16, high) << 8) | low;
                self.registers.a = self.read_memory(address);
            },
            0xC5 => { // PUSH BC
                self.registers.sp -%= 2;
                const sp = self.registers.sp;
                self.memory[sp] = self.registers.b;
                self.memory[sp + 1] = self.registers.c;
            },
            0xD5 => { // PUSH DE
                self.registers.sp -%= 2;
                const sp = self.registers.sp;
                self.memory[sp] = self.registers.d;
                self.memory[sp + 1] = self.registers.e;
            },
            0xE5 => { // PUSH HL
                self.registers.sp -%= 2;
                const sp = self.registers.sp;
                self.memory[sp] = self.registers.h;
                self.memory[sp + 1] = self.registers.l;
            },
            0xF5 => { // PUSH AF
                self.registers.sp -%= 2;
                const sp = self.registers.sp;
                self.memory[sp] = self.registers.a;
                self.memory[sp + 1] = self.registers.f;
            },
            0xC1 => { // POP BC
                self.registers.b = self.read_memory(self.registers.sp);
                self.registers.c = self.read_memory(self.registers.sp + 1);
                self.registers.sp +%= 2;
            },
            0xD1 => { // POP DE
                self.registers.d = self.read_memory(self.registers.sp);
                self.registers.e = self.read_memory(self.registers.sp + 1);
                self.registers.sp +%= 2;
            },
            0xE1 => { // POP HL
                self.registers.h = self.read_memory(self.registers.sp);
                self.registers.l = self.read_memory(self.registers.sp + 1);
                self.registers.sp +%= 2;
            },
            0xF1 => { // POP AF
                self.registers.a = self.read_memory(self.registers.sp);
                self.registers.f = self.read_memory(self.registers.sp + 1);
                self.registers.sp +%= 2;
            },
            0x2F => { // CPL (complement A)
                self.registers.a = ~self.registers.a;
            },
            0x3D => { // DEC A
                self.registers.a -%= 1;
            },
            0x07 => { // RLCA
                const carry = (self.registers.a & 0x80) >> 7;
                self.registers.a = (self.registers.a << 1) | carry;
                // update carry flag (optional now)
            },
            0x0F => { // RRCA
                const carry = self.registers.a & 0x01;
                self.registers.a = (self.registers.a >> 1) | (carry << 7);
                // update carry flag (optional now)
            },
            0xB0 => { // RES 4, B
                // Reset bit 4 of register B (B & 0xEF)
                self.registers.b &= 0xEF;
            },
            0x7B => { // LD A, E
                self.registers.a = self.registers.e;
            },
            0xBF => { // LD A, A (no-op)
                // No operation: A remains unchanged
            },
            0x29 => { // ADD HL, DE
                const hl = self.registers.hl;
                const de = self.registers.de;
                const result = hl +% de;

                // Set the HL register to the result
                self.registers.hl = result;

                // Set the flags
                self.registers.set_zero_flag(result == 0); // Zero flag
                self.registers.set_negative_flag(false); // No subtraction, so Negative flag is clear
                self.registers.set_half_carry_flag((hl & 0xFFF) + (de & 0xFFF) > 0xFFF); // Half carry
                self.registers.set_carry_flag(result > 0xFFFF); // Carry flag
            },
            0x2B => { // DEC HL
                var hl = (@as(u16, self.registers.h) << 8) | self.registers.l;
                hl -%= 1;
                self.registers.h = @truncate(hl >> 8);
                self.registers.l = @truncate(hl);
            },
            0x7C => {
                // LD A, H
                self.registers.a = self.registers.h; // Copy value from H to A
                // No flags are affected
                self.registers.pc += 1; // Move to the next instruction
            },
            0x78 => {
                // LD A, B
                self.registers.a = self.registers.b; // Copy value from B to A
                // No flags are affected
                self.registers.pc += 1; // Move to the next instruction
            },
            0x7F => {
                // LD A, A (No-op: Load A into itself)
                // No changes to registers are necessary since the operation doesn't modify A.
                // But we still need to increment the program counter.
                self.registers.pc += 1;
            },
            0x50 => {
                // LD D, B
                self.registers.d = self.registers.b; // Copy value from B to D
                // No flags are affected
                self.registers.pc += 1; // Move to the next instruction
            },
            0x39 => {
                // ADD HL, SP
                const hl = self.registers.hl;
                const sp = self.registers.sp;
                const result = hl +% sp;

                // Update HL register with the result
                self.registers.hl = result;

                // Set the flags
                self.registers.set_zero_flag(false); // Zero flag is not affected
                self.registers.set_negative_flag(false); // No subtraction, so Negative flag is clear
                self.registers.set_half_carry_flag((hl & 0xFFF) + (sp & 0xFFF) > 0xFFF); // Half carry check
                self.registers.set_carry_flag(result > 0xFFFF); // Carry flag check (overflow)
            },
            0xFF => {
                // RST 38h
                // Push current program counter onto the stack
                self.push_stack(self.registers.pc);

                // Set the program counter to 0x38
                self.registers.pc = 0x38;
            },
            0x38 => {
                // SBC A, n (Subtract with Borrow)
                const n = self.read_memory(self.registers.pc + 1); // Read the immediate value

                // Subtract the immediate value and carry from A
                const carry_flag = self.registers.get_carry_flag();
                const carry_flag_int: u8 = if (carry_flag) 1 else 0;
                const result = self.registers.a - n - @as(u8, carry_flag_int);

                // Set the result back into the accumulator
                self.registers.a = result;

                // Set flags
                self.registers.set_zero_flag(result == 0); // Zero flag
                self.registers.set_negative_flag(true); // Negative flag
                self.registers.set_half_carry_flag((self.registers.a & 0x0F) < (n & 0x0F)); // Half carry
                self.registers.set_carry_flag(self.registers.a > result); // Carry flag

                // Increment the Program Counter (PC) to skip the immediate byte
                self.registers.pc += 2;
            },

            else => {
                std.debug.print("Unknown opcode: {X}\n", .{opcode});
                unreachable;
            },
        }
    }
};
