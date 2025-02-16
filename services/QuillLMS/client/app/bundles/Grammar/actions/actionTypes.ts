
export const ActionTypes = {
  // INIT STORE
  INIT_STORE: 'INIT_STORE',

  // GRAMMAR ACTIVITIES
  RECEIVE_GRAMMAR_ACTIVITY_DATA: 'RECEIVE_GRAMMAR_ACTIVITY_DATA',
  NO_GRAMMAR_ACTIVITY_FOUND: 'NO_GRAMMAR_ACTIVITY_FOUND',
  RECEIVE_GRAMMAR_ACTIVITIES_DATA: 'RECEIVE_GRAMMAR_ACTIVITIES_DATA',
  NO_GRAMMAR_ACTIVITIES_FOUND: 'NO_GRAMMAR_ACTIVITIES_FOUND',
  TOGGLE_NEW_LESSON_MODAL: 'TOGGLE_NEW_LESSON_MODAL',
  AWAIT_NEW_LESSON_RESPONSE: 'AWAIT_NEW_LESSON_RESPONSE',
  RECEIVE_NEW_LESSON_RESPONSE: 'RECEIVE_NEW_LESSON_RESPONSE',
  START_LESSON_EDIT: 'START_LESSON_EDIT',
  SUBMIT_LESSON_EDIT: 'SUBMIT_LESSON_EDIT',
  FINISH_LESSON_EDIT: 'FINISH_LESSON_EDIT',
  EDITING_LESSON: 'EDITING_LESSON',
  SUBMITTING_LESSON: 'SUBMITTING_LESSON',
  START_NEW_ACTIVITY: 'START_NEW_ACTIVITY',

  // QUESTIONS
  RECEIVE_QUESTIONS_DATA: 'RECEIVE_QUESTIONS_DATA',
  RECEIVE_SINGLE_QUESTION_DATA: 'RECEIVE_SINGLE_QUESTION_DATA',
  REMOVE_QUESTION_DATA: 'REMOVE_QUESTION_DATA',
  NO_QUESTIONS_FOUND: 'NO_QUESTIONS_FOUND',
  EDITING_QUESTION: 'EDITING_QUESTION',
  START_QUESTION_EDIT: 'START_QUESTION_EDIT',
  FINISH_QUESTION_EDIT: 'FINISH_QUESTION_EDIT',
  SUBMIT_QUESTION_EDIT: 'SUBMIT_QUESTION_EDIT',
  AWAIT_NEW_QUESTION_RESPONSE: 'AWAIT_NEW_QUESTION_RESPONSE',
  RECEIVE_NEW_QUESTION_RESPONSE: 'RECEIVE_NEW_QUESTION_RESPONSE',
  SUBMITTING_QUESTION: 'SUBMITTING_QUESTION',
  FINISH_RESPONSE_EDIT: 'FINISH_RESPONSE_EDIT',
  CANCEL_CHILD_RESPONSE_VIEW: 'CANCEL_CHILD_RESPONSE_VIEW',
  CANCEL_TO_RESPONSE_VIEW: 'CANCEL_TO_RESPONSE_VIEW',
  SUBMIT_RESPONSE_EDIT: 'SUBMIT_RESPONSE_EDIT',
  TOGGLE_NEW_QUESTION_MODAL: 'TOGGLE_NEW_QUESTION_MODAL',
  SUBMITTING_RESPONSE: 'SUBMITTING_RESPONSE',
  CANCEL_FROM_RESPONSE_VIEW: 'CANCEL_FROM_RESPONSE_VIEW',
  CLEAR_QUESTION_STATE: 'CLEAR_QUESTION_STATE',
  SET_CURRENT_QUESTION: 'SET_CURRENT_QUESTION',

  // QUESTIONS FOR SESSION
  RECEIVE_QUESTION_DATA: 'RECEIVE_QUESTION_DATA',
  NO_QUESTIONS_FOUND_FOR_SESSION: 'NO_QUESTIONS_FOUND_FOR_SESSION',
  GO_T0_NEXT_QUESTION: 'GO_T0_NEXT_QUESTION',
  SUBMIT_RESPONSE: 'SUBMIT_RESPONSE',

  // SESSIONS
  SET_SESSION: 'SET_SESSION',
  START_NEW_SESSION: 'START_NEW_SESSION',
  SET_PROOFREADER_SESSION_TO_REDUCER: 'SET_PROOFREADER_SESSION_TO_REDUCER',
  SET_SESSION_PENDING: 'SET_SESSION_PENDING',
  SET_LANGUAGE: 'SET_LANGUAGE',

  // DISPLAY
  DISPLAY_ERROR: 'DISPLAY_ERROR',
  DISPLAY_MESSAGE: 'DISPLAY_MESSAGE',
  CLEAR_DISPLAY_MESSAGE_AND_ERROR: 'CLEAR_DISPLAY_MESSAGE_AND_ERROR',

  // CONCEPTS
  RECEIVE_CONCEPTS_DATA: 'RECEIVE_CONCEPTS_DATA',

  // RESPONSES
  //
  DELETE_RESPONSE_STATUS: 'DELETE_RESPONSE_STATUS',
  UPDATE_RESPONSE_STATUS: 'UPDATE_RESPONSE_STATUS',
  UPDATE_RESPONSE_DATA: 'UPDATE_RESPONSE_DATA',
  SHOULD_RELOAD_RESPONSES: 'SHOULD_RELOAD_RESPONSES',
  START_RESPONSE_EDIT: 'START_RESPONSE_EDIT',
  DELETE_ALL_SESSION_DATA: 'DELETE_ALL_SESSION_DATA',

  // MASS EDIT
  ADD_RESPONSE_TO_MASS_EDIT_ARRAY: 'ADD_RESPONSE_TO_MASS_EDIT_ARRAY',
  REMOVE_RESPONSE_FROM_MASS_EDIT_ARRAY: 'REMOVE_RESPONSE_FROM_MASS_EDIT_ARRAY',
  CLEAR_RESPONSES_FROM_MASS_EDIT_ARRAY: 'CLEAR_RESPONSES_FROM_MASS_EDIT_ARRAY',
  ADD_RESPONSES_TO_MASS_EDIT_ARRAY: 'ADD_RESPONSES_TO_MASS_EDIT_ARRAY',
  REMOVE_RESPONSES_FROM_MASS_EDIT_ARRAY: 'REMOVE_RESPONSES_FROM_MASS_EDIT_ARRAY',

  // FILTERS
  TOGGLE_EXPAND_SINGLE_RESPONSE: 'TOGGLE_EXPAND_SINGLE_RESPONSE',
  COLLAPSE_ALL_RESPONSES: 'COLLAPSE_ALL_RESPONSES',
  EXPAND_ALL_RESPONSES: 'EXPAND_ALL_RESPONSES',
  TOGGLE_STATUS_FIELD: 'TOGGLE_STATUS_FIELD',
  TOGGLE_STATUS_FIELD_AND_RESET_PAGE: 'TOGGLE_STATUS_FIELD_AND_RESET_PAGE',
  TOGGLE_RESPONSE_SORT: 'TOGGLE_RESPONSE_SORT',
  TOGGLE_EXCLUDE_MISSPELLINGS: 'TOGGLE_EXCLUDE_MISSPELLINGS',
  RESET_ALL_FIELDS: 'RESET_ALL_FIELDS',
  DESELECT_ALL_FIELDS: 'DESELECT_ALL_FIELDS',
  UPDATE_SEARCHED_RESPONSES: 'UPDATE_SEARCHED_RESPONSES',
  SET_RESPONSE_PAGE_NUMBER: 'SET_RESPONSE_PAGE_NUMBER',
  SET_RESPONSE_STRING_FILTER: 'SET_RESPONSE_STRING_FILTER',
  INCREMENT_REQUEST_COUNT: 'INCREMENT_REQUEST_COUNT',

  FEEDBACK_STRINGS: {
    punctuationError: 'There may be an error. How could you update the punctuation?',
    punctuationAndCaseError: 'There may be an error. How could you update the punctuation and capitalization?',
    typingError: 'Try again. There may be a spelling mistake.',
    caseError: 'Proofread your work. There may be a capitalization error.',
    minLengthError: 'Revise your work. Do you have all of the information from the prompt?',
    maxLengthError: 'Revise your work. How could your response be shorter and more concise?',
    modifiedWordError: 'Revise your work. You may have mixed up or misspelled a word.',
    additionalWordError: 'Revise your work. You may have added an extra word.',
    missingWordError: 'Revise your work. You may have left out an important word.',
    whitespaceError: 'There may be an error. You may have forgotten a space between two words.',
    flexibleModifiedWordError: 'Revise your work. You may have mixed up a word.',
    flexibleAdditionalWordError: 'Revise your work. You may have added an extra word.',
    flexibleMissingWordError: 'Revise your work. You may have left out an important word.',
  },

  ERROR_TYPES: [
    'typingError',
    'caseError',
    'punctuationError',
    'punctuationAndCaseError',
    'minLengthError',
    'maxLengthError',
    'flexibleModifiedWordError',
    'flexibleAdditionalWordError',
    'flexibleMissingWordError',
    'modifiedWordError',
    'additionalWordError',
    'missingWordError',
    'whitespaceError',
    'requiredWordsError',
    'tooShortError',
    'tooLongError'
  ],

  ERROR_AUTHORS: [
    'Capitalization Hint',
    'Starting Capitalization Hint',
    'Punctuation Hint',
    'Punctuation and Case Hint',
    'Punctuation End Hint',
    'Modified Word Hint',
    'Additional Word Hint',
    'Missing Word Hint',
    'Flexible Modified Word Hint',
    'Flexible Additional Word Hint',
    'Flexible Missing Word Hint',
    'Whitespace Hint',
    'Spelling Hint',
    'Focus Point Hint',
    'Incorrect Sequence Hint',
    'Quotation Mark Hint',
    'Words Out of Order Hint',
    'Spacing After Comma Hint',
  ],

  // STATE
  START_CHILD_RESPONSE_VIEW: 'START_CHILD_RESPONSE_VIEW',
  START_FROM_RESPONSE_VIEW: 'START_FROM_RESPONSE_VIEW',
  START_TO_RESPONSE_VIEW: 'START_TO_RESPONSE_VIEW',

  // CONCEPTS FEEDBACK
  RECEIVE_CONCEPTS_FEEDBACK_DATA: 'RECEIVE_CONCEPTS_FEEDBACK_DATA',
  START_CONCEPTS_FEEDBACK_EDIT: 'START_CONCEPTS_FEEDBACK_EDIT',
  SUBMIT_CONCEPTS_FEEDBACK_EDIT: 'SUBMIT_CONCEPTS_FEEDBACK_EDIT',
  FINISH_CONCEPTS_FEEDBACK_EDIT: 'FINISH_CONCEPTS_FEEDBACK_EDIT',
  TOGGLE_NEW_CONCEPTS_FEEDBACK_MODAL: 'TOGGLE_NEW_CONCEPTS_FEEDBACK_MODAL',
  AWAIT_NEW_CONCEPTS_FEEDBACK_RESPONSE: 'AWAIT_NEW_CONCEPTS_FEEDBACK_RESPONSE',
  RECEIVE_NEW_CONCEPTS_FEEDBACK_RESPONSE: 'RECEIVE_NEW_CONCEPTS_FEEDBACK_RESPONSE',
  SUBMITTING_CONCEPTS_FEEDBACK: 'SUBMITTING_CONCEPTS_FEEDBACK',

  // INCORRECT SEQUENCES
  SET_USED_SEQUENCES: 'SET_USED_SEQUENCES',

  // QUESTION AND CONCEPT MAP
  RECEIVE_GRAMMAR_QUESTION_AND_CONCEPT_MAP: 'RECEIVE_GRAMMAR_QUESTION_AND_CONCEPT_MAP',
};
//
