# WAS: Weighted Average Score

A simple gem/dsl for generating Weighted Average Score calculations.

## Example Usage

Scenario:
* A person has a final report that is scored based on two parts:
  * A practical test score, worth 25% of the total
  * An Exam score, worth 75%
* The exam is given a grade: A, B, C, F
  * 'A' is worth 100%
  * 'B' is 75%
  * 'C' is 50%
  * 'D' is 0%
* The practical is a simple mark out of 10.
  * 4 out of 10 is 40%
* The person is given a final score out of 1000.

### Define score classes

```ruby
require "was"

class ReportScore < WAS::Score
  maximum_score 1000

  with :exam,      class_name: "ExamScore",      weight: 0.75
  with :practical, class_name: "PracticalScore", weight: 0.25
end

class ExamScore < WAS::Score
  context :grade_a, score: 1 do |input|
    input == "A"
  end

  context :grade_b, score: 0.75 do |input|
    input == "B"
  end

  context :grade_c, score: 0.5 do |input|
    input == "C"
  end

  context :flunk do
    0
  end
end

class PracticalScore < WAS::Score
  context :score do |input|
    input / 10.0
  end
end
```

### Generate a total score

```ruby
ReportScore.new(
  exam: "A",
  practical: 10
).calculate
#> 1000

ReportScore.new(
  exam: "F",
  practical: 10
).calculate
#> 250
````

### Compose without generating a total score

Omitting the `maximum_score` will return a composed percentage represented as a value between `0` and `1`.

```ruby
# report_score.rb
class ReportScore < WAS::Score
  with :exam,      class_name: "ExamScore",      weight: 0.75
  with :practical, class_name: "PracticalScore", weight: 0.25
end
```

```ruby
# usage
ReportScore.new({
  exam: "A",
  practical: 5
}).calculate
#> 0.875
```

### Working with a score tree

For more complex scenarios, we might need to know more about how the score was composed.

Using the example `ReportScore`, `ExamScore`, and `PracticalScore` classes as
an example, we can generate a tree of scores:

```ruby
tree = ReportScore.new({
  exam: "A",
  practical: 5
}).calculate(:tree)

#> tree
{
  score: 875.0,
  max: 1000,
  deduction: -125.0,
  with: {
    exam: {
      score: 750.0,
      max: 750.0,
      deduction: 0.0,
      weight: 0.75
    },
    practical: {
      score: 125.0,
      max: 250.0,
      deduction: -125.0,
      weight: 0.25
    }
  }
}
```

This result is a `WAS::Tree` object. Basically a `Hash` with some extra
added to it.

#### Ordering by attribute

For each of the key attributes `:score`, `:max`, `:weight`, and
`:deduction`, we can order our tree interally by that key:

```ruby
#> tree.order(:deduction)
{
  score: 875.0,
  max: 1000,
  deduction: -125.0
  with: {
    practical: {
      score: 125.0,
      max: 250.0,
      deduction: -125.0,
      weight: 0.25
    },
    exam: {
      score: 750.0,
      max: 750.0,
      deduction: 0.0,
      weight: 0.75
    }
  }
}
```

For `:deduction`, results adjacent to each other are ordered by the
_most negative_. For all other options, the values are ordered largest
value first.

### View all weights

If you want to see all of the weights that are used to compose the score,
there is a convenience method `.weights`:

```ruby
ReportScore.weights
#> {exam: {weight: 0.75}, practical: {weight: 0.25}}
