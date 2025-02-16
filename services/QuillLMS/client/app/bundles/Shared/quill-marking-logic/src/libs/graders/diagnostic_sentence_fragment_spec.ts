import { responses, incorrectSequences, focusPoints } from '../../../test/data/batswings'
// import {checkDiagnosticSentenceFragment} from './sentence_fragment'
import {checkDiagnosticSentenceFragment} from './diagnostic_sentence_fragment'
import {Response} from '../../interfaces';
import { feedbackStrings } from '../constants/feedback_strings';
import {spacingBeforePunctuation} from '../algorithms/spacingBeforePunctuation'

describe('The checking a sentence fragment', () => {
  const initialFields = {
    question_uid: 'questionOne',
    response: responses[0].text,
    responses,
    wordCountChange: {min: 1, max: 3},
    ignoreCaseAndPunc: false,
    incorrectSequences,
    focusPoints,
    prompt: 'Bats have wings they can fly.',
    defaultConceptUID: responses[0].question_uid
  };

  describe('first matchers - original sentence', () => {
    it('should be able to find an exact match', () => {
      const fields = {
        ...initialFields,
        question_uid: responses[0].question_uid,
        wordCountChange: {min: 1, max: 4}
      };
      const matchedResponse = checkDiagnosticSentenceFragment(fields);
      matchedResponse.then(resp => {
        expect(resp.id).toEqual(responses[0].id);
      })
    });

    it('should be able to find a match, even with trailing spaces', () => {
      const fields = {
        ...initialFields,
        response: 'Bats have wings, so they can fly. ',
      };
      const matchedResponse = checkDiagnosticSentenceFragment(fields);
      matchedResponse.then(resp => {
        expect(resp.id).toEqual(responses[0].id);
      })
    });

    it('should be able to find a match, even with extra spaces', () => {
      const fields = {
        ...initialFields,
        response: 'Bats have wings,  so they can fly.',
      };
      const matchedResponse = checkDiagnosticSentenceFragment(fields);
      matchedResponse.then(resp => {
        expect(resp.id).toEqual(responses[0].id);
      })
    });

    it('should be able to find an incorrect sequence match', () => {
      // this is a little artificial, as the focus point (looking for the word 'so') encompasses the incorrect sequence (using the phrase 'and they')
      const fields = {
        ...initialFields,
        response: 'So bats have wings and they can fly.',
      };
      const matchedResponse = checkDiagnosticSentenceFragment(fields);
      matchedResponse.then(resp => {
        expect(resp.feedback).toEqual(incorrectSequences[0].feedback);
      })
    });

    it('should be able to find a focus point match', () => {
      // this is a little artificial, as the focus point (looking for the word 'so') encompasses the incorrect sequence (using the phrase 'and they')
      const fields = {
        ...initialFields,
        response: 'Bats have wings which means that they can fly.',
      };
      const matchedResponse = checkDiagnosticSentenceFragment(fields);
      matchedResponse.then(resp => {
        expect(resp.feedback).toEqual(focusPoints[0].feedback);
      })
    });
    //
    it('should be able to find a length match', () => {
      const fields = {
        ...initialFields,
        response: 'Bats have wings, so means that they can fly very far.',
      };
      const matchedResponse = checkDiagnosticSentenceFragment(fields);
      matchedResponse.then(resp => {
        expect(resp.feedback).toEqual('Revise your work. Add one to three words to the prompt to make the sentence complete.');
      })
    })

    it('should be able to find a case insensitive match', () => {
      const fields = {
        ...initialFields,
        response: "bats have wings, so they can fly.",
      };
      const matchedResponse = checkDiagnosticSentenceFragment(fields);
      matchedResponse.then(resp => {
        expect(resp.feedback).toEqual(feedbackStrings.caseError)
        expect(resp.concept_results[0].conceptUID).toEqual(responses[0].question_uid);
      })
    });

    it('should be able to find a punctuation insensitive match', () => {
      const fields = {
        ...initialFields,
        response: "Bats have wings so they can fly far",
      };
      const matchedResponse = checkDiagnosticSentenceFragment(fields);
      matchedResponse.then(resp => {
        expect(resp.feedback).toEqual(feedbackStrings.punctuationError);
        expect(resp.concept_results[0].conceptUID).toEqual(responses[0].question_uid);
      })
    });

    it('should be able to find a punctuation and case insensitive match', () => {
      // const responseString = "bats have wings so they can fly."
      // const matchedResponse = checkDiagnosticSentenceFragment('questionOne', responseString, responses, {min: 1, max: 3}, false, incorrectSequences, 'Bats have wings they can fly.');
      // expect(matchedResponse.feedback).toEqual(feedbackStrings.punctuationAndCaseError);
    });

    it('should be able to find a spacing before punctuation match', () => {
      const fields = {
        ...initialFields,
        response: "Bats have wings so they can fly far .",
      };
      const matchedResponse = checkDiagnosticSentenceFragment(fields);
      matchedResponse.then(resp => {
        expect(resp.feedback).toEqual(spacingBeforePunctuation("Bats have wings so they can fly far .").feedback);
        expect(resp.concept_results[0].conceptUID).toEqual(responses[0].question_uid);
      });
    });

    it('should be able to find a spacing after comma match', () => {
      const fields = {
        ...initialFields,
        response: "Bats have wings,so they can fly far.",
      };
      const matchedResponse = checkDiagnosticSentenceFragment(fields);
      matchedResponse.then(resp => {
        expect(resp.feedback).toEqual(feedbackStrings.spacingAfterCommaError);
        expect(resp.concept_results[0].conceptUID).toEqual(responses[0].question_uid);
      });
    });
  });
});
