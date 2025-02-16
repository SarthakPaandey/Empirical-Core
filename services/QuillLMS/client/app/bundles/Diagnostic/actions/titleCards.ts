import { push } from 'react-router-redux';
import { DIAGNOSTIC_TITLE_CARD_TYPE, TitleCardApi } from '../libs/title_cards_api';
import sessionActions from './sessions';

import C from '../constants';


function startListeningToTitleCards() {
  return loadTitleCards();
}

function loadTitleCards(): (any) => void {
  return (dispatch) => {
    TitleCardApi.getAll(DIAGNOSTIC_TITLE_CARD_TYPE).then((body) => {
      let titleCards = body.title_cards || []
      const titleCardsObject = titleCards.reduce((obj, item) => {
        return Object.assign(obj, {[item.uid]: item});
      }, {});
      dispatch({ type: C.RECEIVE_TITLE_CARDS_DATA, data: titleCardsObject, });
    });
  };
}

function loadSpecifiedTitleCards(uids) {
  return (dispatch, getState) => {
    const requestPromises: Promise<TitleCardProps>[] = [];
    uids.forEach((uid) => {
      requestPromises.push(TitleCardApi.get(DIAGNOSTIC_TITLE_CARD_TYPE, uid));
    });
    const allPromises: Promise<TitleCardProps[]> = Promise.all(requestPromises);
    const questionData = {};
    allPromises.then((results) => {
      results.forEach((result) => {
        questionData[result.uid] = result;
      });
      sessionActions.populateQuestions("TL", questionData, true)
      dispatch({ type: C.RECEIVE_TITLE_CARDS_DATA, data: questionData, });
    });
  }
}

function submitNewTitleCard(content) {
  return (dispatch) => {
    TitleCardApi.create(DIAGNOSTIC_TITLE_CARD_TYPE, content).then((body) => {
      dispatch({ type: C.RECEIVE_TITLE_CARDS_DATA_UPDATE, data: {[body.uid]: body} });
      const action = push(`/admin/title-cards/${body.uid}`);
      dispatch(action);
    })
      .catch((body) => {
        dispatch({ type: C.DISPLAY_ERROR, error: `Submission failed! ${body}`, });
      });
  };
}

function submitTitleCardEdit(uid, content) {
  return (dispatch, getState) => {
    TitleCardApi.update(DIAGNOSTIC_TITLE_CARD_TYPE, uid, content).then((body) => {
      dispatch({ type: C.RECEIVE_TITLE_CARDS_DATA_UPDATE, data: {[body.uid]: body} });
      dispatch({ type: C.DISPLAY_MESSAGE, message: 'Update successfully saved!', });
      const action = push(`/admin/title-cards/${uid}`);
      dispatch(action);
    }).catch((body) => {
      dispatch({ type: C.DISPLAY_ERROR, error: `Update failed! ${body}`, });
    });
  };
}

export {
  loadSpecifiedTitleCards, loadTitleCards, startListeningToTitleCards, submitNewTitleCard, submitTitleCardEdit
};

