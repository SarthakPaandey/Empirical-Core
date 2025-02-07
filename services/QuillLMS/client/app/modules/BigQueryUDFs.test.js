import { tierUDF, studentwiseSkillGroupUDF, findLastIndex, parseElement, deduplicateAndAverageScores } from "./BigQueryUDFs"

function zip(scores, activityIds, completedAts, skillGroupNames) {
  return scores.map((score, idx) => ([score, activityIds[idx], completedAts[idx], skillGroupNames[idx]].join('|')))
}

describe('studentwiseSkillGroupUDF', () => {
  it('should return skillGroup-score pairs', () => {
    const activityIds = ["1663", "1663", "1664", "1664"];
    const completedAts = ['2022-01-01T00:00:00Z', '2022-01-01T00:01:00Z', '2022-01-02T00:00:00Z', '2022-01-02T00:01:00Z'];
    const scores = ["false", "false", "true", "true"];
    const skillGroupNames = ['Plural and Possessive Nouns', 'Capitalization', 'Plural and Possessive Nouns', 'Capitalization' ]

    const zipped = zip(scores, activityIds, completedAts, skillGroupNames)

    const result = studentwiseSkillGroupUDF(zipped);
    const parsedResult = JSON.parse(result)

    expect(parsedResult['Plural and Possessive Nouns_pre']).toEqual(0)
    expect(parsedResult['Capitalization_pre']).toEqual(0)
    expect(parsedResult['Plural and Possessive Nouns_post']).toEqual(1)
    expect(parsedResult['Capitalization_post']).toEqual(1)
  })

  it('should extract correct spanned-activity counts', () => {
    const recommendedActivity = ""
    const notRecommendedActivity = "1"
    const activityIds = ["1663", recommendedActivity, notRecommendedActivity, "1664"];
    const completedAts = ['2022-01-01T00:00:00Z', '2022-01-01T00:01:00Z', '2024-01-01T00:01:00Z',  '2022-01-02T00:00:00Z'];
    const scores = ["false", "false", "true", "true"];
    const skillGroupNames = "a b c d".split(' ')

    const zipped = zip(scores, activityIds, completedAts, skillGroupNames)

    const result = studentwiseSkillGroupUDF(zipped);
    const parsedResult = JSON.parse(result)
    expect(parsedResult.Capitalization_tier).toEqual("0/7")
  })

  it('should remove commas from skill group names that have commas', () => {
    const activityIds = ["1663", "1664"];
    const completedAts = ['2022-01-01T00:00:00Z', '2022-01-02T00:00:00Z'];
    const scores = ["false", "true"];
    const skillGroupNames = ['Compound Subjects, Objects, and Predicates', 'Compound Subjects, Objects, and Predicates']

    const zipped = zip(scores, activityIds, completedAts, skillGroupNames)

    const result = studentwiseSkillGroupUDF(zipped);
    const parsedResult = JSON.parse(result)

    expect(parsedResult['Compound Subjects Objects and Predicates_pre']).toEqual(0)
    expect(parsedResult['Compound Subjects Objects and Predicates_post']).toEqual(1)

  })
})

describe('parseElement', () => {
  it('should parse elements correctly', () => {
    const inputString = "true|1668|2023-10-31 13:37:19.789202|Subject-Verb Agreement"
    const expectedOutput = {
      scores: [1],
      activityId: 1668,
      completedAt: "2023-10-31 13:37:19.789202",
      skillGroupName: "Subject-Verb Agreement"
    }

    expect(parseElement(inputString)).toEqual(expectedOutput)
  })

  it('should throw error on invalid input', () => {
    const inputString = "bad|input"

    expect(() => (parseElement(inputString))).toThrow(`Invalid element string: ${inputString}`)
  })
})

describe('deduplicateAndAverageScores', () => {
  it('should dedupe and average', () => {
    const input = [
      {scores: [1], activityId: 1, skillGroupName: 'a', completedAt: "2023-10-31 13:37:19.789202"},
      {scores: [0], activityId: 1, skillGroupName: 'a', completedAt: "2023-10-31 13:37:19.789202"},
      {scores: [1], activityId: 1, skillGroupName: 'b', completedAt: "2023-10-31 13:37:19.789202"}
    ]

    const expected = [
      {score: .5, activityId: 1, skillGroupName: 'a', completedAt: "2023-10-31 13:37:19.789202"},
      {score: 1, activityId: 1, skillGroupName: 'b', completedAt: "2023-10-31 13:37:19.789202"}
    ]

    expect(deduplicateAndAverageScores(input)).toEqual(expected)
  })
})

describe('findLastIndex', () => {
  it('should return the correct index', () => {
    const finderFn = (x) => x === 4
    const arr = [2, 4, 6, 4]
    expect(findLastIndex(arr, 0, finderFn)).toEqual(3)
  })

  it('should return the correct index, with 2-element array', () => {
    const finderFn = (x) => x === 4
    const arr = [2, 4]
    expect(findLastIndex(arr, 0, finderFn)).toEqual(1)
  })

  it('should return the correct index, with 1-element array', () => {
    const finderFn = (x) => x === 4
    const arr = [2, 4]
    expect(findLastIndex(arr, 1, finderFn)).toEqual(1)
  })
})

