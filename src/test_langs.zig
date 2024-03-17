const std = @import("std");
const math = std.math;
const testing = std.testing;
// const allocatortest = testing.allocator;
const Allocator = std.mem.Allocator;
const heap = std.heap.HeapAllocator;

test "fn reflection" {
    try testing.expect(@typeInfo(@TypeOf(testing.expect)).Fn.params[0].type.? == bool);
    try testing.expect(@typeInfo(@TypeOf(testing.tmpDir)).Fn.return_type.? == testing.TmpDir);
    try testing.expect(@typeInfo(@TypeOf(math.Log2Int)).Fn.is_generic);
}

const FileOpenError = error{
    AccessDenied,
    OutOfMemory,
    FileNotFound,
};

const AllocationError = error{
    OutOfMemory,
};

test "coerce subset to superset error set type" {
    const err = fooErrorSet(AllocationError.OutOfMemory);
    try std.testing.expect(err == FileOpenError.OutOfMemory);
}

fn fooErrorSet(err: AllocationError) FileOpenError {
    return err;
}

fn fooErrorSetInverted(err: FileOpenError) AllocationError {
    return err;
}

test "coerce superset to subset is not allowed in error set type" {
    // will error
    // fooErrorSetInverted(FileOpenError.OutOfMemory) catch {};

    const err = error.FileNotFound;
    const err2 = (error{FileNotFound}).FileNotFound;
    try testing.expectEqual(err, err2);
}

pub fn parseU64(buf: []const u8, radix: u8) anyerror!u64 {
    var x: u64 = 0;

    for (buf) |c| {
        const digit = charToDigit(c);
        if (digit >= radix) {
            return error.InvalidChar;
        }

        var ov = @mulWithOverflow(x, radix);
        if (ov[1] != 0) return error.Overflow;

        ov = @addWithOverflow(ov[0], digit);
        if (ov[1] != 0) return error.Overflow;
        x = ov[0];
    }

    return x;
}

fn charToDigit(c: u8) u8 {
    return switch (c) {
        '0'...'9' => c - '0',
        'A'...'Z' => c - 'A' + 10,
        'a'...'z' => c - 'z' + 10,
        else => math.maxInt(u8),
    };
}

test "parse u64" {
    const result = try parseU64("1234", 10);
    try testing.expect(result == 1234);
}

fn doAThing(str: []const u8) u64 {
    const number = parseU64(str, 10) catch 13;
    return number;
}

fn doAThing2(str: []const u8) void {
    const number = parseU64(str, 10) catch blk: {
        std.debug.print("I AM SPEED\n", .{});
        break :blk 13;
    };
    std.debug.print("number is: {}\n", .{number});
}

test "parse u64 error catch" {
    const result = doAThing("123");
    try testing.expectEqual(result, 123);
    try testing.expectEqual(doAThing("99999999999999999999999"), 13);
}

fn doAThing3(str: []const u8) !void {
    const result = parseU64(str, 10) catch |err| return err;
    std.debug.print("i send this: {}", .{result});
}

fn doAThing4(str: []const u8) void {
    if (parseU64(str, 10)) |number| {
        doSomethingWithNumber(number);
    } else |err| switch (err) {
        error.Overflow => {
            std.debug.print("i am overflowing bro\n", .{});
        },
        error.InvalidChar => unreachable,
        else => {
            std.debug.print("Why are we still here?\n", .{});
        },
    }
}

fn doSomethingWithNumber(number: u64) void {
    std.debug.print("doSomethingWithNumber says: {}\n", .{number});
}

fn doAThing5(str: []const u8) error{InvalidChar}!void {
    if (parseU64(str, 10)) |number| {
        doSomethingWithNumber(number);
    } else |err| switch (err) {
        error.Overflow => {
            std.debug.print("i am overflowing bro\n", .{});
        },
        else => {
            std.debug.print("just die \n", .{});
        },
    }
}

fn doADifferentThing(str: []const u8) void {
    if (parseU64(str, 10)) |number| {
        doSomethingWithNumber(number);
    } else |_| {
        std.debug.print("WHERE IS YOUR GOD NOW ?!", .{});
    }
}

const Foo = struct {
    data: u32,
};

fn tryAllocateFoo(allocator: Allocator) !*Foo {
    return allocator.create(Foo);
}

fn deallocateFoo(allocator: Allocator, foo: *Foo) void {
    allocator.destroy(foo);
}

fn getFooData() !u32 {
    return 666;
}

fn createFoo(allocator: Allocator, param: i32) !*Foo {
    const foo = getFoo: {
        var foo = try tryAllocateFoo(allocator);

        // calls deallocateFoo if on error here
        foo.data = try getFooData();

        break :getFoo foo;
    };
    errdefer deallocateFoo(allocator, foo); // only last until the end of getFoo label

    // outside if getFoo, errdefer will not be called
    if (param > 1337) return error.InvalidParam;

    return foo;
}

test "createFoo" {
    try std.testing.expectError(error.InvalidParam, createFoo(std.testing.allocator, 2468));
}

fn getFoo() !u32 {
    return 666;
}

const Foo2 = struct {
    data: *u32,
};

fn genFoos(allocator: Allocator, num: usize) ![]Foo2 {
    const foos = try allocator.alloc(Foo2, num);
    errdefer allocator.free(foos);

    var num_allocated: usize = 0;
    errdefer for (foos[0..num_allocated]) |foo| {
        allocator.destroy(foo.data);
    };

    for (foos, 0..) |*foo, i| {
        foo.data = try allocator.create(u32);

        num_allocated += 1;

        if (i >= 3) return error.TooManyFoos;
        // std.debug.print("foo#: {}\n", .{i});

        foo.data.* = try getFoo();
    }

    // i assume the checked num_allocator is explicit and called here
    return foos;
}

test "genFoos" {
    try std.testing.expectError(error.TooManyFoos, genFoos(std.testing.allocator, 5));
}

test "error union" {
    var foo: anyerror!i32 = undefined;

    foo = 1234;

    foo = error.SomeError;

    try comptime std.testing.expect(@typeInfo(@TypeOf(foo)).ErrorUnion.payload == i32);
    try comptime std.testing.expect(@typeInfo(@TypeOf(foo)).ErrorUnion.error_set == anyerror);
}

const A = error{
    NotDir,

    /// A doc
    PathNotFound,
};

const B = error{
    OutOfMemory,

    /// B doc
    PathNotFound,
};

const C = A || B;

fn foo2() C!void {
    return error.NotDir;
}

test "merged error sets" {
    if (foo2()) {
        @panic("broooo! come on....");
        // unreachable;
    } else |err| switch (err) {
        error.OutOfMemory => @panic("oom"),
        error.PathNotFound => @panic("pnf"),
        error.NotDir => {},
    }
}

pub fn add_error_inferred(comptime T: type, a: T, b: T) !T {
    const ov = @addWithOverflow(a, b);
    if (ov[1] != 0) return error.Overflow;
    return ov[0];
}

const Error = error{
    Overflow,
};

pub fn add_error_explicit(comptime T: type, a: T, b: T) Error!T {
    const ov = @addWithOverflow(a, b);
    if (ov[1] != 0) return error.Overflow;
    return ov[0];
}

test "inferred error set " {
    if (add_error_inferred(u8, 255, 1)) |_| unreachable else |err| switch (err) {
        error.Overflow => {},
    }
}

// pub fn main() !void {
//     // doAThing2("123111111");
//     // doAThing2("9999999999999999999999999999");
//     //
//     // const number = doAThing3("999") catch unreachable;
//     // std.debug.print("i got this: {}", .{number});
//     //
//     // doAThing4("99999999999999999999999");
//
//     // try doAThing5("99999999999999999999999");
//
//     // doADifferentThing("99999999999999999999999");
//
//     std.debug.print("{}", .{genFoos(heap, 5)});
// }
