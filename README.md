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

    with "ExamScore",      weight: 0.75
    with "PracticalScore", weight: 0.25
  end

  class ExamScore < WAS::Score
    def calculation
      return 1    if input == "A"
      return 0.75 if input == "B"
      return 0.5  if input == "C"
      0
    end
  end

  class PracticalScore < WAS::Score
    def calculation
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
  class ComposedScore < WAS::Score
    with "ExamScore",      weight: 0.75
    with "PracticalScore", weight: 0.25
  end
```

```ruby
ComposedScore.new({
  exam: "A",
  practical: 5
}).calculate
#> 0.875
```

### View all weights

If you want to see all of the weights that are used to compose the score, there is a convenience method `.weights`:

```ruby
ReportScore.weights
#> {exam: {weight: 0.75}, practical: {weight: 0.25}}
