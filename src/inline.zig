const std = @import("std");

inline fn foo3(a: i32, b: i32) i32 {
    return a + b;
}

// pub fn main() !void {
test "test inline" {
    const a: i32 = 1200;
    const b: i32 = 34;
    const result: i32 = foo3(a, b);
    std.debug.print("RESULT: {}", .{result});
    if (result != 1234) {
        @compileError("bad");
    }
}

const FileOpenError = error{
    AccessDenied,
    OutOfMemory,
    FileNotFound,
};

const AllocationError = error{
    OutOfMemory,
};
