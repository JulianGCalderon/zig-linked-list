const std = @import("std");
const list = @import("list.zig");
const List = list.List;
const ListError = list.ListError;

pub fn main() !void {}

const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;
const expectError = testing.expectError;
const allocator = testing.allocator;

test "Can create empty list" {
    const l = List(u32).init(allocator);
    defer l.deinit();

    try expectEqual(l.len(), 0);
    try expect(l.empty());
}

test "Given an empty list, can push an element" {
    var l = List(u32).init(allocator);
    defer l.deinit();

    try l.push(1);

    try expect(!l.empty());
    try expectEqual(l.len(), 1);
    try expectEqual(l.get(0), 1);
}

test "Given an empty list, can push multiple elements" {
    var l = List(u32).init(allocator);
    defer l.deinit();

    try l.push(1);
    try l.push(2);
    try l.push(3);

    try expect(!l.empty());
    try expectEqual(l.len(), 3);
    try expectEqual(l.get(0), 1);
    try expectEqual(l.get(1), 2);
    try expectEqual(l.get(2), 3);
}

test "Given a list with one element, can remove it" {
    var l = List(u32).init(allocator);
    defer l.deinit();

    try l.push(1);
    const removed = try l.pop();

    try expect(l.empty());
    try expectEqual(l.len(), 0);
    try expectEqual(removed, 1);
    try expectError(ListError.IndexOutOfBounds, l.get(0));
}

test "Given a list with multiple elements, can remove all of them" {
    var l = List(u32).init(allocator);
    defer l.deinit();

    try l.push(1);
    try l.push(2);
    try l.push(3);
    const removed3 = try l.pop();
    const removed2 = try l.pop();
    const removed1 = try l.pop();

    try expect(l.empty());
    try expectEqual(l.len(), 0);
    try expectEqual(removed1, 1);
    try expectEqual(removed2, 2);
    try expectEqual(removed3, 3);
    try expectError(ListError.IndexOutOfBounds, l.get(0));
}
