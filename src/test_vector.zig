const std = @import("std");

const expectEqual = std.testing.expectEqual;

test "basic vector usage" {
    const a = @Vector(4, i32){ 1, 2, 3, 4 };
    const b = @Vector(4, i32){ 5, 6, 7, 8 };

    const c = a + b;
    try expectEqual(6, c[0]);
    try expectEqual(8, c[1]);
    try expectEqual(10, c[2]);
    try expectEqual(12, c[3]);
}

test "Conversion between vectors, arrays, and slices" {
    const arr1: [4]f32 = [_]f32{ 1.1, 3.2, 4.5, 5.6 };
    const vec: @Vector(4, f32) = arr1;
    const arr2: [4]f32 = vec;
    try expectEqual(arr1, arr2);

    const vec2: @Vector(2, f32) = arr1[1..3].*;
    const slice: []const f32 = &arr1;
    var offset: u32 = 1;
    const vec3: @Vector(2, f32) = slice[offset..][0..2].*;

    try expectEqual(slice[offset], vec2[0]);
    try expectEqual(slice[offset + 1], vec2[1]);
    try expectEqual(vec2, vec3);
}

pub fn main() !void {
    var arr1: [4]f32 = [_]f32{ 1.1, 3.2, 4.5, 5.6 };
    var vec: @Vector(4, f32) = arr1;
    var arr2: [4]f32 = vec;
    try expectEqual(arr1, arr2);

    const vec2: @Vector(2, f32) = arr1[1..3].*;

    std.debug.print("arr1: {any}\n", .{arr1});
    std.debug.print("vec:  {any}\n", .{vec});
    std.debug.print("arr2: {any}\n", .{arr2});
    std.debug.print("vec2: {any}\n", .{vec2});

    std.debug.print("\n", .{});

    arr1[1] = 7.6;
    arr1[1] = 6.6;
    vec[1] = 7.7;
    std.debug.print("arr1: {any}\n", .{arr1});
    std.debug.print("vec:  {any}\n", .{vec});
    std.debug.print("arr2: {any}\n", .{arr2});
    std.debug.print("vec2: {any}\n", .{vec2});

    // const slice: []const f32 = &arr1;
    // var offset: u32 = 1;
    // const vec3: @Vector(2, f32) = slice[offset..][0..2].*;

    // try expectEqual(slice[offset], vec2[0]);
    // try expectEqual(slice[offset + 1], vec2[1]);
    // try expectEqual(vec2, vec3);
}
