(use judge)

# given a list of comparators, return a comparator that tries each of them
# in order until one returnes non-zero
(defn then [& comparators] (fn [a b]
  (var result 0)
  (for i 0 (length comparators)
    (def comparator (in comparators i))
    (set result (comparator a b))
    (when (not= 0 result)
      (break)))
  result))

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

(test (cmp 1 2) -1)
(test ((desc cmp) 1 2) 1)

# lifts a comparator to a comparator that acts over lists.
# shorter lists compare before longer lists if the short
# list is a prefix of the longer list
(defn list [comparator] (fn [as bs]
  (var result 0)
  (var i 0)
  (def len-as (length as))
  (def len-bs (length bs))
  (for i 0 (min len-as len-bs)
    (def a (in as i))
    (def b (in bs i))
    (set result (comparator a b))
    (when (not= 0 result)
      (break)))
  (if (= result 0)
    (cmp len-as len-bs)
    result)))

(test ((list cmp) [1 2 3] [1 2 2]) 1)
(test ((list cmp) [1 2 3] [1 2 2 5]) 1)
(test ((list cmp) [1 2 3] [1 2 4]) -1)
(test ((list cmp) [1 2 3] [1 2]) 1)
(test ((list cmp) [] [1 2 3]) -1)
(test ((list cmp) [1 2 3] []) 1)

(def- core/sort sort)
(def- core/sorted sorted)

(defn- before? [cmp] (fn [a b] (neg? (cmp a b))))

(defn sort [list & comparators]
  (if (= 1 (length comparators))
    (core/sort list (before? (first comparators)))
    (core/sort list (before? (then ;comparators)))))

(defn sorted [list & comparators]
  (if (= 1 (length comparators))
    (core/sorted list (before? (first comparators)))
    (core/sorted list (before? (then ;comparators)))))

(test (sort @[3 1 2] cmp) @[1 2 3])
(test (sorted [2 1 3] cmp) @[1 2 3])
(test (sorted [2 1 3] (desc cmp)) @[3 2 1])

(test (sorted [{:a 1 :b 1} {:a 1 :b 0} {:a 1 :b -1}] (by :a) (by :b))
  @[{:a 1 :b -1} {:a 1 :b 0} {:a 1 :b 1}])

(test (sorted [{:a {:x 1} :b 1} {:a {:x 2} :b 0} {:a {:x 1} :b -1}] (by :a (by :x)) (by :b))
  @[{:a {:x 1} :b -1}
    {:a {:x 1} :b 1}
    {:a {:x 2} :b 0}])
