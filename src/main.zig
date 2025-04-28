const std = @import("std");

const Registers = struct {
    a: u8,
    b: u8,
    c: u8,
    d: u8,
    e: u8,
    h: u8,
    l: u8,
    f: u8,
    pc: u16, // Program Counter
    sp: u16, // Stack Pointer (later)
};

const Cpu = struct {
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
            0x15 => { // DEC D
                self.registers.d -= 1;
                // Handle flags (Z, N, H) later if needed
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
            0x2C => { // INC L
                self.registers.l += 1;
                // You can later handle flags (Z, N, H) here if needed
            },
            0x2D => { // DEC L
                self.registers.l -= 1;
                // You can later handle flags (Z, N, H) here if needed
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

            else => {
                std.debug.print("Unknown opcode: {X}\n", .{opcode});
                unreachable;
            },
        }
    }
};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    try stdout.print("Enter path to .gb file: ", .{});

    var input_buffer: [256]u8 = undefined;
    const input = try stdin.readUntilDelimiterOrEof(&input_buffer, '\n');
    const path = std.mem.trimRight(u8, input orelse "", "\r\n");

    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();

    const rom = try file.readToEndAlloc(allocator, 10 * 1024 * 1024); // Read up to 10MB
    defer allocator.free(rom);

    var cpu = Cpu.init();
    cpu.load_rom(rom);

    try stdout.print("Loaded ROM successfully!\n", .{});

    cpu.run();
    try stdout.print("CPU execution finished.\n", .{});
}
