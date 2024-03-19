const std = @import("std");
const math = std.math;
const testing = std.testing;
// const allocatortest = testing.allocator;
const Allocator = std.mem.Allocator;
const heap = std.heap.HeapAllocator;
const expect = std.testing.expect;

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

fn fooo(x: i32) !void {
    if (x >= 5) {
        try baar();
    } else {
        try bang2();
    }
}

fn baar() !void {
    if (baz()) {
        try quux();
    } else |err| switch (err) {
        error.FileNotFound => try hello(),
    }
}

fn baz() !void {
    try bang1();
}

fn quux() !void {
    try bang2();
}

fn hello() !void {
    try bang2();
}

fn bang1() !void {
    return error.FileNotFound;
}

fn bang2() !void {
    return error.PermissionDenied;
}

const normal_int: i32 = 1234;
const optional_int: ?i32 = 2345;
const optional_value: ?i32 = null;

test "optional type" {
    var foo: ?i32 = null;
    foo = 1234;
    try comptime std.testing.expect(@typeInfo(@TypeOf(foo)).Optional.child == i32);
}

test "optional pointer" {
    var ptr: ?*i32 = null;
    var x: i32 = 1;
    ptr = &x;

    try std.testing.expectEqual(ptr.?.*, 1);
    x = 2;
    try std.testing.expectEqual(ptr.?.*, 2);

    try std.testing.expectEqual(@sizeOf(?*i32), @sizeOf(*i32));
}

test "type coercion - fn call" {
    const a: u8 = 1;
    foo4(a);
}

fn foo4(b: u16) void {
    _ = b;
}

test "type coercion - @as builtin function" {
    const a: u8 = 1;
    const b = @as(u16, a);
    _ = b;
}

test "type coercion - const qualif" {
    var a: i32 = 1;
    _ = &a;
    const b: *i32 = &a;
    foo5(b);
    try std.testing.expectEqual(a, 123);
}

fn foo5(c: *i32) void {
    c.* = 123;
}

test "cast *[1][*]const u8 to [*]const ?[*]const u8" {
    const window_name = [1][*]const u8{"window name"};
    const x: [*]const ?[*]const u8 = &window_name;
    try std.testing.expect(std.mem.eql(u8, std.mem.sliceTo(@as([*:0]const u8, @ptrCast(x[0].?)), 0), "window name"));
}

test "integer widening" {
    const a: u8 = 253;
    const b: u16 = a;
    const c: u32 = b;
    const d: u64 = c;
    const e: u64 = d;
    const f: u128 = e;
    try std.testing.expect(a == f);
}

test "implicit unsigned integer to signed integer" {
    const a: u8 = 250;
    const b: i16 = a;
    try std.testing.expect(b == 250);
}

test "float widening" {
    const a: f16 = 12.34;
    const b: f32 = a;
    const c: f64 = b;
    const d: f128 = c;

    try std.testing.expect(a == d);
}

// test "implicit cast to comptime_int" {
//     const f: f32 = 54.0 / 5;
//     _ = f;
// }

test "*const [N]T to []const T" {
    const x1: []const u8 = "hello";
    const x2: []const u8 = &[5]u8{ 'h', 'e', 'l', 'l', 111 };
    try std.testing.expect(std.mem.eql(u8, x1, x2));

    const y: []const f32 = &[2]f32{ 1.2, 3.4 };
    try std.testing.expect(y[0] == 1.2);
    try std.testing.expect(y[1] == 3.4);
}

test "*const [T]T to E![]const T" {
    const x1: anyerror![]const u8 = "hello";
    const x2: anyerror![]const u8 = &[5]u8{ 'h', 'e', 'l', 'l', 111 };
    try std.testing.expect(std.mem.eql(u8, try x1, try x2));

    const y: anyerror![]const f32 = &[2]f32{ 1.2, 3.4 };
    try std.testing.expect((try y)[0] == 1.2);
    try std.testing.expect((try y)[1] == 3.4);
}

test "*const [N]T to ?[]const T" {
    const x1: ?[]const u8 = "hello";
    const x2: ?[]const u8 = &[5]u8{ 'h', 'e', 'l', 'l', 111 };
    try std.testing.expect(std.mem.eql(u8, x1.?, x2.?));

    const y: ?[]const f32 = &[2]f32{ 1.2, 3.4 };
    try std.testing.expect(y.?[0] == 1.2);
    try std.testing.expect(y.?[1] == 3.4);
}

test "*[N]T to []T" {
    var buf: [5]u8 = "hello".*;
    const x: []u8 = &buf;
    try std.testing.expect(std.mem.eql(u8, x, "hello"));

    const buf2 = [2]f32{ 1.2, 3.4 };
    const x2: []const f32 = &buf2;
    try std.testing.expect(std.mem.eql(f32, x2, &[2]f32{ 1.2, 3.4 }));
}

test "*[N]T to [*]T" {
    var buf: [5]u8 = "hello".*;
    const x: [*]u8 = &buf;
    try std.testing.expect(x[4] == 'o');
}

test "*[N]T to ?[*]T" {
    var buf: [5]u8 = "hello".*;
    const x: ?[*]u8 = &buf;
    try std.testing.expect(x.?[4] == 'o');
}

test "*[N]T to *[1]T" {
    var x: i32 = 1234;
    const y: *[1]i32 = &x;
    const z: [*]i32 = y;
    try std.testing.expect(z[0] == 1234);
}

test "coerce to optional" {
    const x: ?i32 = 1234;
    const y: ?i32 = null;
    try expect(x.? == 1234);
    try expect(y == null);
}

test "coerce to optional wrapped in error union" {
    const x: anyerror!?i32 = 1234;
    const y: anyerror!?i32 = null;
    try expect((try x).? == 1234);
    try expect((try y) == null);
}

test "coercion to error unions" {
    const x: anyerror!i32 = 1234;
    const y: anyerror!i32 = error.Failure;

    try expect((try x) == 1234);
    try std.testing.expectError(error.Failure, y);
}

test "coercing large integer to smaller one (comptime known can fit)" {
    const x: u64 = 255;
    const y: u8 = x;

    try expect(y == 255);
}

const E = enum {
    one,
    two,
    three,
};

const U = union(E) {
    one: i32,
    two: f32,
    three,
};

const U2 = union(enum) {
    a: void,
    b: f32,
    fn tag(self: U2) usize {
        switch (self) {
            .a => return 1,
            .b => return 2,
        }
    }
};

test "coercion between union and enums" {
    const u = U{ .two = 12.23 };
    const e: E = u;
    try expect(e == E.two);

    const three = E.three;
    const u_2: U = three;
    try expect(u_2 == E.three);

    const u_3: U = .three;
    try expect(u_3 == U.three);
    try expect(u_3 == E.three);

    const u_4: U2 = .a;
    try expect(u_4.tag() == 1);

    const u_5: U2 = .{ .b = 201 };
    try expect(u_5.tag() == 2);
    try expect(u_5.b == 201);
}

const Tuple = struct { u8, u8 };
test "coercion from tuple to array" {
    const tuple: Tuple = .{ 5, 6 };
    const array: [2]u8 = tuple;
    try expect(array[0] == 5);
    try expect(array[1] == 6);
}

pub fn main() !void {
    // doAThing2("123111111");
    // doAThing2("9999999999999999999999999999");
    //
    // const number = doAThing3("999") catch unreachable;
    // std.debug.print("i got this: {}", .{number});
    //
    // doAThing4("99999999999999999999999");

    // try doAThing5("99999999999999999999999");

    // doADifferentThing("99999999999999999999999");

    // std.debug.print("{}", .{genFoos(heap, 5)});

    try fooo(13);
}
