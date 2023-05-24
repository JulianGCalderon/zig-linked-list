const std = @import("std");
const list = @import("list.zig");
const List = list.List;
const ListError = list.ListError;

const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;
const expectError = testing.expectError;
const allocator = testing.allocator;

test "Can create empty list" {
    const l = List(u32).init(allocator);
    defer l.deinit();

    try expectEqual(l.length(), 0);
    try expect(l.empty());
}

test "Given an empty list, can push an element" {
    var l = List(u32).init(allocator);
    defer l.deinit();

    try l.push(1);

    try expect(!l.empty());
    try expectEqual(l.length(), 1);
    try expectEqual(l.get(0), 1);
}

test "Given an empty list, can push multiple elements" {
    var l = List(u32).init(allocator);
    defer l.deinit();

    try l.push(1);
    try l.push(2);
    try l.push(3);

    try expect(!l.empty());
    try expectEqual(l.length(), 3);
    try expectEqual(l.get(0), 1);
    try expectEqual(l.get(1), 2);
    try expectEqual(l.get(2), 3);
}

test "Given a list with one element, can pop it" {
    var l = List(u32).init(allocator);
    defer l.deinit();

    try l.push(1);
    const removed = try l.pop();

    try expect(l.empty());
    try expectEqual(l.length(), 0);
    try expectEqual(removed, 1);
    try expectError(ListError.IndexOutOfBounds, l.get(0));
}

test "Given a list with multiple elements, can pop all of them" {
    var l = List(u32).init(allocator);
    defer l.deinit();

    try l.push(1);
    try l.push(2);
    try l.push(3);
    const removed3 = try l.pop();
    const removed2 = try l.pop();
    const removed1 = try l.pop();

    try expect(l.empty());
    try expectEqual(l.length(), 0);
    try expectEqual(removed1, 1);
    try expectEqual(removed2, 2);
    try expectEqual(removed3, 3);
    try expectError(ListError.IndexOutOfBounds, l.get(0));
}

test "Given a list multiple elements, can insert in inbetween position" {
    var l = List(u32).init(allocator);
    defer l.deinit();

    try l.push(0);
    try l.push(0);
    try l.push(0);

    try l.insert(1, 1);

    try expectEqual(l.length(), 4);
    try expectEqual(l.get(0), 0);
    try expectEqual(l.get(1), 1);
    try expectEqual(l.get(2), 0);
    try expectEqual(l.get(3), 0);
}

test "Given a list multiple elements, can remove an element in an inbetween position" {
    var l = List(u32).init(allocator);
    defer l.deinit();

    try l.push(0);
    try l.push(1);
    try l.push(0);
    try l.push(0);

    const element = try l.remove(1);

    try expectEqual(l.length(), 3);
    try expectEqual(element, 1);
    try expectEqual(l.get(0), 0);
    try expectEqual(l.get(1), 0);
    try expectEqual(l.get(2), 0);
}

test "Given a list with multiple elements, can remove elements from the first position" {
    var l = List(u32).init(allocator);
    defer l.deinit();

    try l.push(0);
    try l.push(1);
    try l.push(2);
    try l.push(3);

    const element0 = try l.remove(0);
    const element1 = try l.remove(0);
    const element2 = try l.remove(0);
    const element3 = try l.remove(0);

    try expectEqual(l.length(), 0);
    try expectEqual(element0, 0);
    try expectEqual(element1, 1);
    try expectEqual(element2, 2);
    try expectEqual(element3, 3);
}

test "Given an empty list, can push a slice" {
    var l = List(usize).init(allocator);
    defer l.deinit();

    var numbers = [_]usize{ 1, 2, 3 };

    try l.push_slice(numbers[0..]);

    try expectEqual(l.length(), 3);
    try expectEqual(l.get(0), 1);
    try expectEqual(l.get(1), 2);
    try expectEqual(l.get(2), 3);
}

fn adder(element: u32, sum: *u32) bool {
    sum.* += element;
    return true;
}

fn conditional_adder(element: u32, sum: *u32) bool {
    sum.* += element;
    return element != 0;
}

test "Given a list with multiple elements, when iterating internally, can access all elements" {
    var l = List(u32).init(allocator);
    defer l.deinit();

    try l.push(1);
    try l.push(2);
    try l.push(3);
    try l.push(4);

    var sum: u32 = 0;
    const counted = l.for_each_element(&sum, adder);

    try expectEqual(counted, 4);
    try expectEqual(sum, 10);
}

test "Given a list with multiple elements, when iterating internally, stops on first false" {
    var l = List(u32).init(allocator);
    defer l.deinit();

    try l.push(1);
    try l.push(2);
    try l.push(0);
    try l.push(3);

    var sum: u32 = 0;
    const counted = l.for_each_element(&sum, conditional_adder);

    try expectEqual(counted, 3);
    try expectEqual(sum, 3);
}

test "Given a list with multiple elements, when iterating externally, can access all elements" {
    var l = List(u32).init(allocator);
    defer l.deinit();

    try l.push(0);
    try l.push(1);
    try l.push(2);
    try l.push(3);

    var i = l.iterator();

    try expectEqual(i.next(), 0);
    try expectEqual(i.next(), 1);
    try expectEqual(i.next(), 2);
    try expectEqual(i.next(), 3);
}

test "Can create a list with different types" {
    var l = List(*const void).init(allocator);
    defer l.deinit();

    const element1 = 1;
    const element2 = "Hola";
    const element3 = 3.14;

    const void_element1 = @ptrCast(*const void, &element1);
    const void_element2 = @ptrCast(*const void, &element2);
    const void_element3 = @ptrCast(*const void, &element3);

    try l.push(void_element1);
    try l.push(void_element2);
    try l.push(void_element3);

    try expectEqual(l.length(), 3);
    try expectEqual(l.get(0), void_element1);
    try expectEqual(l.get(1), void_element2);
    try expectEqual(l.get(2), void_element3);
}
