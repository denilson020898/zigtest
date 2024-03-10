const std = @import("std");
const expect = std.testing.expect;

test "comptime vars" {
    var x: i32 = 1;
    comptime var y: i32 = 1;

    x += 1;
    y += 1;

    try expect(x == 2);
    try expect(y == 2);

    if (y != 2) {
        @compileError("wrong y value");
    }
}

fn babi() !i32 {
    var x: i32 = 1;
    comptime var y: i32 = 1;

    x += 1;
    y += 1;

    try expect(x == 2);
    try expect(y == 2);

    if (y != 2) {
        @compileError("wrong y value");
    }
    return y;
}

pub fn main() !void {
    const y = try babi();
    std.debug.print("haha {d}", .{y});
}
