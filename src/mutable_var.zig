const print = @import("std").debug.print;

pub fn main() !void {
    var y: i32 = 5678;
    print("{d}", .{y});
    y += 1;
    print("{d}", .{y});
}
