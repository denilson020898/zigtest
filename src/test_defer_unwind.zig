const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const builtin = @import("builtin");
const native_arch = builtin.cpu.arch;
const testing = std.testing;
const math = std.math;

test "defer unwind" {
    std.debug.print("\n", .{});

    defer {
        std.debug.print("1 ", .{});
    }

    defer {
        std.debug.print("2 ", .{});
    }

    if (false) {
        defer {
            std.debug.print("3 ", .{});
        }
    }
}

fn defer3() u8 {
    // defer {
    //     return 1;
    // }
    return 2;
}

test "basic math" {
    const x = 1;
    const y = 2;
    if (x + y != 3) {
        unreachable;
    }
}

// fn assert(ok: bool) void {
//     if (!ok) unreachable;
// }

test "this will fail" {
    // assert(false);
    assert(true);
}

test "type of unreachable" {
    comptime {
        // assert(@TypeOf(unreachable) == noreturn);
    }
}

fn foo(condition: bool, b: u32) void {
    const a = if (condition) b else return;
    _ = a;
    @panic("do something with a");
}

test "noreturn" {
    foo(false, 1);
}

// const WINAPI: std.builtin.CallingConvention = if (native_arch == .x86) .StdCall else .C;
// extern "kernel32" fn ExitProcess(exit_code: c_uint) callconv(WINAPI) noreturn;
//
// test "noreturn from exit" {
//     const value = bar() catch ExitProcess(1);
//     try expect(value == 1234);
// }
//
// fn bar() anyerror!u32 {
//     return 1234;
// }

fn add(a: i8, b: i8) i8 {
    if (a == 0) {
        return b;
    }
    return a + b;
}

fn sub(a: i8, b: i8) i8 {
    return a - b;
}

inline fn shiftLeftOne(a: u32) u32 {
    return a << 1;
}

const fn_ptr = *const fn (a: i8, b: i8) i8;
fn doOp(fnCall: fn_ptr, op1: i8, op2: i8) i8 {
    return fnCall(op1, op2);
}

test "functions" {
    try expect(doOp(add, 5, 6) == 11);
    try expect(doOp(sub, 5, 6) == -1);
}

const Point = struct {
    x: i32,
    y: i32,
};

fn foo2(point: Point) i32 {
    return point.x + point.y;
}

test "pass struct to function" {
    try expect(foo2(Point{ .x = 1, .y = 2 }) == 3);
}

fn addFortyTwo(x: anytype) @TypeOf(x) {
    return x + 42;
}

test "fn type inference" {
    try expect(addFortyTwo(1) == 43);
    try expect(@TypeOf(addFortyTwo(1)) == comptime_int);

    const y: i64 = 2;
    try expect(addFortyTwo(y) == 44);
    try expect(@TypeOf(addFortyTwo(y)) == i64);
}

test "inline fn call" {
    const result = foo3(1200, 34);
    std.debug.print("RESULT: {}", .{result});
    if (result != 1234) {
        @compileError("bad");
    }
}

inline fn foo3(a: i32, b: i32) i32 {
    return a + b;
}

test "fn reflection" {
    try expect(@typeInfo(@TypeOf(expect)).Fn.params[0].type.? == bool);
    try expect(@typeInfo(@TypeOf(testing.tmpDir)).Fn.return_type.? == testing.TmpDir);
}

fn test2(
    aaaasdfasdf: i32,
    bbbasdfasdf: i32,
    cccasdfasdf: i32,
    dddasdfasdf: i32,
    eeeasdfasdf: i32,
) i32 {
    return aaaasdfasdf + bbbasdfasdf + cccasdfasdf + dddasdfasdf + eeeasdfasdf;
}
