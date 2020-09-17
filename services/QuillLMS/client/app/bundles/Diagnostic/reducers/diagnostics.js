import { SubmitActions } from '../actions/diagnostics.js';
 // / make this playLessonsReducer.
const initialState = {
  answeredQuestions: [],
  unansweredQuestions: [],
  languageMenuOpen: false,
  diagnosticID: null
};

function question(state = initialState, action) {
  let changes = {}
  switch (action.type) {
    case SubmitActions.NEXT_DIAGNOSTIC_QUESTION:
      if (state.currentQuestion) {
        changes.answeredQuestions = state.answeredQuestions.concat([state.currentQuestion]);
      }
      changes.currentQuestion = state.unansweredQuestions[0];
      if (changes.currentQuestion) {
        changes.currentQuestion.data.attempts = [];
      }
      if (state.unansweredQuestions.length > 0) {
        changes.unansweredQuestions = state.unansweredQuestions.slice(1);
      }
      return Object.assign({}, state, changes);
    case SubmitActions.NEXT_DIAGNOSTIC_QUESTION_WITHOUT_SAVING:
      changes.currentQuestion = state.unansweredQuestions[0];
      if (changes.currentQuestion) {
        changes.currentQuestion.data.attempts = [];
      }
      if (state.unansweredQuestions.length > 0) {
        changes.unansweredQuestions = state.unansweredQuestions.slice(1);
      }
      return Object.assign({}, state, changes);
    case SubmitActions.LOAD_DIAGNOSTIC_DATA:
      var changes2 = {
        unansweredQuestions: action.data,
        questionSet: action.data, };
      return Object.assign({}, state, changes2);
    case SubmitActions.CLEAR_DIAGNOSTIC_DATA:
      return initialState;
    case SubmitActions.EXIT_DIAGNOSTIC:
      return Object.assign({}, state, {
        completedQuestions: undefined,
        answeredQuestions: [],
        unansweredQuestions: [],
      });
    case SubmitActions.SUBMIT_DIAGNOSTIC_RESPONSE:
      if (state.currentQuestion && state.currentQuestion.data) {
        changes = { currentQuestion: Object.assign({}, state.currentQuestion, {
          data: Object.assign({},
            state.currentQuestion.data,
            {
              attempts: state.currentQuestion.data.attempts.concat([action.response]),
            }),
          }),
        };
        return Object.assign({}, state, changes);
      }
    case SubmitActions.START_DIAGNOSTIC_QUESTION:
      changes = { currentQuestion:
      Object.assign({}, state.currentQuestion, {
        started: true,
      }), };
      return Object.assign({}, state, changes);
    case SubmitActions.UPDATE_DIAGNOSTIC_NAME:
      changes = { name: action.data, };
      return Object.assign({}, state, changes);
    case SubmitActions.UPDATE_DIAGNOSTIC_LANGUAGE:
      changes = { language: action.data, };
      return Object.assign({}, state, changes);
    case SubmitActions.UPDATE_DIAGNOSTIC_CURRENT_QUESTION:
      var change = action.data;
      changes = { currentQuestion: Object.assign({}, state.currentQuestion, {
        data: Object.assign({},
            state.currentQuestion.data,
            change
          ),
      }), };
      return Object.assign({}, state, changes);
    case SubmitActions.RESUME_PREVIOUS_DIAGNOSTIC_SESSION:
      return Object.assign({}, state, action.data);
    case SubmitActions.OPEN_DIAGNOSTIC_LANGUAGE_MENU:
      return Object.assign({}, state, { languageMenuOpen: true, });
    case SubmitActions.CLOSE_DIAGNOSTIC_LANGUAGE_MENU:
      return Object.assign({}, state, { languageMenuOpen: false, });
    case SubmitActions.SET_DIAGNOSTIC_ID:
      return Object.assign({}, state, action.data);
    default:
      return state;
  }
}

export default question;