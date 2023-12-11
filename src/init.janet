(use judge)

(defn- then* [comparators]
  (def len (length comparators))
  (case len
    0 cmp
    1 (first comparators)
    (fn [a b]
      (var result 0)
      (for i 0 len
        (def comparator (in comparators i))
        (set result (comparator a b))
        (when (not= 0 result)
          (break)))
      result)))

# given a list of comparators, return a comparator that tries each of them
# in order until one returnes non-zero
(defn then [& comparators] (then* comparators))

(defn by [f &opt comparator]
  (default comparator cmp)
  (def f (if (keyword? f) (fn [x] (in x f)) f))
  (fn [a b] (comparator (f a) (f b))))

(test ((by |($ :a)) {:a 1} {:a 3}) -1)
(test ((by |($ :a)) {:a 3} {:a 1}) 1)
(test ((by :a) {:a 1} {:a 3}) -1)
(test ((by :a) {:a 2} {:a 2}) 0)

# descending
(defn desc [comparator]
  (fn [a b] (* -1 (comparator a b))))

(defn desc [& args]
  (case (length args)
    0 (desc cmp)
    1 (let [comparator (args 0)] (fn [a b] (* -1 (comparator a b))))
    2 (* -1 (cmp (args 0) (args 1)))
    (error "too many arguments to (desc))")))

(deftest "with one argument, desc reverses a comparator"
  (test ((desc cmp) 1 2) 1))

(deftest "with two arguments, desc asks as a comparator in its own right"
  (test (cmp 1 2) -1)
  (test (desc 1 2) 1))

# lifts a comparator to a comparator that acts over iterables.
# shorter iterables compare before longer iterables if the short
# iterable is a prefix of the longer iterable
(defn each [comparator] (fn [as bs]
  (var result 0)
  (var a-iterator (next as))
  (var b-iterator (next bs))
  (while (and (not= nil a-iterator) (not= nil b-iterator))
    (def a (get as a-iterator))
    (def b (get bs b-iterator))
    (set result (comparator a b))
    (set a-iterator (next as a-iterator))
    (set b-iterator (next bs b-iterator))
    (when (not= 0 result)
      (break)))
  (if (= result 0)
    (if (= a-iterator nil)
      (if (= b-iterator nil) 0 -1)
      1)
    result)))

(test ((each cmp) [1 2 3] [1 2 2]) 1)
(test ((each cmp) [1 2 3] [1 2 2 5]) 1)
(test ((each cmp) [1 2 3] [1 2 4]) -1)
(test ((each cmp) [1 2 3] [1 2]) 1)
(test ((each cmp) [] [1 2 3]) -1)
(test ((each cmp) [1 2 3] []) 1)
(test ((each cmp) [1 2 3] [1 2 3]) 0)
(test ((each cmp) (coro (yield 1) (yield 2) (yield 3)) [1 2 3]) 0)
(test ((each cmp) (coro (yield 1) (yield 2) (yield 4)) [1 2 3]) 1)
(test ((each cmp) (coro (yield 1) (yield 2) (yield 3)) [1 2 4]) -1)
(test ((each cmp)
  (coro (yield 1) (yield 2) (yield 3))
  (coro (yield 1) (yield 2) (yield 3)))
  0)
(test ((each cmp)
  (coro (yield 1) (yield 2) (yield 3))
  (coro (yield 1) (yield 2) (yield 4)))
  -1)
(test ((each cmp)
  (coro (yield 1) (yield 2))
  (coro (yield 1) (yield 2) (yield 3)))
  -1)
(test ((each cmp)
  (coro (yield 1) (yield 2) (yield 3))
  (coro (yield 1) (yield 2) (yield 2)))
  1)
(test ((each cmp) (coro (yield 1) (yield 2)) [1 2 3]) -1)
(test ((each cmp) (coro (yield 1) (yield 2) (yield 3)) [1 2]) 1)

(deftest "default cmp sorts all arrays before all tuples"
  (test (cmp [5] @[1]) 1)
  (test (cmp [1] @[5]) 1))

(def- core/sort sort)
(def- core/sorted sorted)

(defn- before? [comparator] (fn [a b] (neg? (comparator a b))))

(defn sort [arr & comparators]
  (core/sort arr (before? (then* comparators))))

(defn sorted [ind & comparators]
  (core/sorted ind (before? (then* comparators))))

(test (sort @[3 1 2] cmp) @[1 2 3])
(test (sorted [2 1 3] cmp) @[1 2 3])
(test (sorted [2 1 3] (desc cmp)) @[3 2 1])

(test (sorted [{:a 1 :b 1} {:a 1 :b 0} {:a 1 :b -1}] (by :a) (by :b))
  @[{:a 1 :b -1} {:a 1 :b 0} {:a 1 :b 1}])

(test (sorted [{:a {:x 1} :b 1} {:a {:x 2} :b 0} {:a {:x 1} :b -1}] (by :a (by :x)) (by :b))
  @[{:a {:x 1} :b -1}
    {:a {:x 1} :b 1}
    {:a {:x 2} :b 0}])

(deftest "sorts work with no comparators"
  (test (sort @[2 1 3]) @[1 2 3])
  (test (sorted [3 1 2]) @[1 2 3]))

(deftest "descending comparators"
  (test (sorted [2 1 3] desc) @[3 2 1])
  (test (sorted [{:a 1 :b 1} {:a 2 :b 0} {:a 1 :b -1}] (by :a desc) (desc (by :b)))
    @[{:a 2 :b 0} {:a 1 :b 1} {:a 1 :b -1}]))
