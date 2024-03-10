const std = @import("std");
const builtin = @import("builtin");
const eq = std.testing.expectEqual;
const expect = std.testing.expect;
const fmt = std.fmt;
const mem = std.mem;

test "test pointer castings" {
    const bytes align(@alignOf(u32)) = [_]u8{ 0x12, 0x12, 0x12, 0x12 };
    const u32_ptr: *const u32 = @ptrCast(&bytes);

    try eq(u32_ptr.*, 0x12121212);

    const u32_value = std.mem.bytesAsSlice(u32, bytes[0..])[0];
    try eq(u32_value, 0x12121212);

    try eq(@as(u32, @bitCast(bytes)), 0x12121212);
}

test "pointer child type" {
    std.debug.print("\n{any}\n", .{@typeInfo(*u32)});
    std.debug.print("\n{any}\n", .{@typeInfo(*u32).Pointer.child});
    try eq(@typeInfo(*u32).Pointer.child, u32);
}

test "variable alignment" {
    var x: i32 = 1234;
    const align_of_i32 = @alignOf(@TypeOf(x));
    try eq(@TypeOf(&x), *i32);
    try eq(*i32, *align(align_of_i32) i32);
    if (builtin.target.cpu.arch == .x86_64) {
        try eq(@typeInfo(*i32).Pointer.alignment, 4);
    }
}

var foo: u8 align(4) = 100;

test "global vars align" {
    try eq(@typeInfo(@TypeOf(&foo)).Pointer.alignment, 4);

    try eq(@TypeOf(&foo), *align(4) u8);

    // const as_pointer_to_array: *align(4) [1]u8 = &foo;
    // const as_slice: []align(4) u8 = as_pointer_to_array;
    // const as_unaligned_slice: []u8 = as_slice;

    const as_ptr_to_arr: *align(4) [1]u8 = &foo;
    const as_slice: []align(4) u8 = as_ptr_to_arr;
    const as_unaligned_slice: []u8 = as_slice;

    try expect(as_unaligned_slice[0] == 100);
}

fn derp() align(@sizeOf(usize) * 2) i32 {
    return 1234;
}

fn noop1() align(1) void {}
fn noop4() align(4) void {}

test "function alignment" {
    try eq(derp(), 1234);
    try eq(@TypeOf(noop1), fn () align(1) void);
    try eq(@TypeOf(noop4), fn () align(4) void);
    noop1();
    noop4();
}

fn foo2(bytes: []u8) u32 {
    // const slice4 = bytes[1..5]; // failed
    const slice4 = bytes[0..];
    const int_slice = std.mem.bytesAsSlice(u32, @as([]align(4) u8, @alignCast(slice4)));
    return int_slice[0];
}

test "align cast" {
    var array align(4) = [_]u32{ 0x11111111, 0x11111111 };
    const bytes = std.mem.sliceAsBytes(array[0..]);
    try expect(foo2(bytes) == 0x11111111);
}

test "allowzero" {
    var zero: usize = 0;
    _ = &zero;

    const ptr: *allowzero i32 = @ptrFromInt(zero);
    try eq(@intFromPtr(ptr), 0);
}

test "basic slices" {
    var array = [_]i32{ 1, 2, 3, 4 };
    var known_at_runtime_zero: usize = 0;
    _ = &known_at_runtime_zero;

    const slice = array[known_at_runtime_zero..array.len];
    try eq(@TypeOf(slice), []i32);
    try eq(&slice[0], &array[0]);
    try eq(slice.len, array.len);

    const slice2 = array[known_at_runtime_zero .. array.len - 2];
    try eq(slice2.len, array.len - 2);

    const array_ptr = array[0..array.len];
    try eq(@TypeOf(array_ptr), *[array.len]i32);
    try eq(array_ptr.len, slice.len);

    var runtime_start: usize = 1;
    _ = &runtime_start;
    const length = 2;
    const array_ptr_len = array[runtime_start..][0..length];
    try eq(@TypeOf(array_ptr_len), *[length]i32);

    try eq(@TypeOf(&slice[0]), *i32);

    try eq(@TypeOf(slice.ptr), [*]i32);
    try eq(@intFromPtr(slice.ptr), @intFromPtr(&slice[0]));

    // slice[10] += 1;
}

test "using slice for strings" {
    const hello: []const u8 = "hello";
    const world: []const u8 = "世界";

    var all: [100]u8 = undefined;
    var start: usize = 0;
    _ = &start;
    const all_slice = all[start..];
    const hello_world = try fmt.bufPrint(all_slice, "{s} {s}", .{ hello, world });
    // _ = hello_world;
    try expect(mem.eql(u8, hello_world, "hello 世界"));
}

test "slice pointer" {
    var array: [10]u8 = undefined;
    const ptr = &array;
    try eq(@TypeOf(ptr), *[10]u8);

    var start: usize = 0;
    var end: usize = 5;
    const slice = ptr[start..end];

    _ = .{ &start, &end };

    try eq(@TypeOf(slice), []u8);
    slice[2] = 3;
    try eq(array[2], 3);

    const ptr2 = slice[2..3];
    try eq(ptr2.len, 1);
    try eq(ptr2[0], 3);
    try eq(@TypeOf(ptr2), *[1]u8);
}

test "sentinel slice" {
    const slice: [:0]const u8 = "hello";
    try eq(slice.len, 5);
    try eq(slice[5], 0);
}

test "sentinel slicings" {
    var array = [_]u8{ 3, 2, 1, 0, 3, 2, 1, 0 };
    var rt_len: usize = 3;
    _ = &rt_len;

    const slice = array[0..rt_len :0];

    try eq(@TypeOf(slice), [:0]u8);
    try eq(slice.len, 3);
}

test "sentilen UB" {
    var array = [_]u8{ 3, 2, 1, 0 };
    // var rt_len: usize = 2;
    var rt_len: usize = 3;
    _ = &rt_len;
    const slice = array[0..rt_len :0];
    _ = slice;
}
