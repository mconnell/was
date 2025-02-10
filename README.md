# WAS: Weighted Average Score

A simple gem/dsl for generating Weighted Average Score calculations.

## Example Usage

```ruby
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
