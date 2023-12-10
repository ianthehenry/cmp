# cmp

Comparator helpers for Janet.

Instead of `(import cmp)`, you can use `(use cmp/import)` to bring the functions `by` and `desc` into scope unprefixed, as well as all of the other functions prefixed with `cmp/`.

This will let you write code like `(cmp/sort [1 2 3] (by (desc cmp)))`.

```janet
(then & comparators)
```

Returns a comparator that tries each comparator in order until one returns non-zero.

```janet
(by f &opt comparator)
```

`comparator` defaults to `cmp`. You can nest `by` to compare nested keys: `(by :a (by :b))` compares structs like `{:a {:b 0}}`.

If `f` is a keyword, it acts as a getter, not a method name. So `(by :x)` is the same as `(by |(in $ :x))`.

```janet
(desc comparator)
```

Returns a comparator that inverts the other comparator.

```janet
(list comparator)
```

Lifts a comparator to a comparator over. Note that Janet's built-in `cmp` already works over lists, but this is useful for lifting a custom comparator, e.g. `(list (by :x))`.

```janet
(sort list & comparators)
(sorted list & comparators)
```

Wrapped versions of Janet's built-in `sort` and `sorted` that expect comparators instead of a `before?` predicate. If multiple comparators are passed, they're combined with `then`.