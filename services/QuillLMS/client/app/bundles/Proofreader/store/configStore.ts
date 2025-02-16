import { Dispatch, applyMiddleware, createStore } from "redux";
import { composeWithDevTools } from "redux-devtools-extension/developmentOnly";
import thunk from "redux-thunk";
// import { TodoItem } from "../model/TodoItem";
import { initStoreAction } from "../actions/actions";
import { rootReducer } from "../reducers/rootReducer";

export interface IState {
    questions: any;
    grammarActivities: any;
}

export const initStore = () => {
  return (dispatch: Dispatch<{}>) => {
    const initialState = {
      questions: {},
      grammarActivities: {}
    }
    return dispatch(initStoreAction(initialState));
  };
};

export const configureStore = () => {
  if (process.env.NODE_ENV === "production") {
    return createStore(
      rootReducer,
      applyMiddleware(thunk),
    );
  } else {
    return createStore(
      rootReducer,
      composeWithDevTools(
        applyMiddleware(thunk),
      ),
    );
  }
};
