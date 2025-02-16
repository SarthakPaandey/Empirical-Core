import { quotationMarkChecker, quotationMarkMatch } from './quotation_mark_match';

import {Response,PartialResponse} from '../../interfaces'
import {feedbackStrings} from '../constants/feedback_strings'
import {conceptResultTemplate} from '../helpers/concept_result_template'

describe('The quotationMarkMatch function', () => {

  const savedResponses: Array<Response> = [
    {
      id: 1,
      text: "My dog took a nap.",
      feedback: "Good job, that's a sentence!",
      optimal: true,
      count: 2,
      question_uid: "questionOne"
    },
    {
      id: 2,
      text: "My dog took another nap.",
      feedback: "Good job, that's a sentence!",
      optimal: true,
      count: 1,
      question_uid: "questionTwo"
    }
  ]

  it('Should take a response string and return true if response does not contain two adjacent single quotes', () => {
    const responseString = "There are adjacent single quotes in \'\' this string.";
    expect(quotationMarkMatch(responseString, savedResponses)).toBeTruthy()
  });

  it('Should take a response string and return false if response does not contain two adjacent single quotes', () => {
    const responseString = "There are only double \" \" quotes in this string.";
    expect(quotationMarkMatch(responseString, savedResponses)).toBeFalsy()
  });

  it('Should take a response string and find top optimal response if the response string contains two adjacent single quotes', () => {
    const responseString = "There are two adjacent single quotes \'\' in this string.";
    const partialResponse: PartialResponse =  {
      feedback: feedbackStrings.quotationMarkError,
      author: 'Quotation Mark Hint',
      parent_id: quotationMarkChecker(responseString, savedResponses).id,
      concept_results: [
        conceptResultTemplate('TWgxAwCxRjDLPzpZWYmGrw')
      ]
    }
    expect(quotationMarkChecker(responseString, savedResponses).feedback).toEqual(partialResponse.feedback);
    expect(quotationMarkChecker(responseString, savedResponses).author).toEqual(partialResponse.author);
    expect(quotationMarkChecker(responseString, savedResponses).concept_results.length).toEqual(partialResponse.concept_results.length);
  });

});
