(declare-project
  :name "cmp"
  :description "comparison combinators"
  :dependencies ["https://github.com/ianthehenry/judge.git"]
  )

(declare-source
  :prefix "cmp"
  :source [
    "src/init.janet"
    "src/import.janet"
  ])
