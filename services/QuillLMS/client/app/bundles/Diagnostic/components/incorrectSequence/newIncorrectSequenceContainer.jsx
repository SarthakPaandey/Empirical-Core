import React, { Component } from 'react';
import _ from 'underscore';
import { connect } from 'react-redux';

import ResponseComponent from '../questions/responseComponent'
import questionActions from '../../actions/questions';
import sentenceFragmentActions from '../../actions/sentenceFragments.ts';
import { IncorrectSequencesInputAndConceptSelectorForm, } from '../../../Shared/index';

class NewIncorrectSequencesContainer extends Component {
  constructor() {
    super();

    const questionType = window.location.href.includes('sentence-fragments') ? 'sentenceFragments' : 'questions'
    const questionTypeLink = questionType === 'sentenceFragments' ? 'sentence-fragments' : 'questions'
    const actionFile = questionType === 'sentenceFragments' ? sentenceFragmentActions : questionActions

    this.state = { questionType, actionFile, questionTypeLink };
  }

  UNSAFE_componentWillMount() {
    const { actionFile } = this.state;
    const { dispatch, generatedIncorrectSequences, match } = this.props;
    const { used } = generatedIncorrectSequences;
    const { params, url } = match;
    const { questionID } = params;
    const type = url.includes('sentence-fragments') ? 'sentence-fragment' : 'sentence-combining'
    if (!used[questionID]) {
      dispatch(actionFile.getUsedSequences(questionID, type))
    }
  }

  submitSequenceForm = data => {
    const { dispatch, history, match, questions } = this.props;
    const { actionFile } = this.state;
    const incorrectSequences = questions.data[match.params.questionID].incorrectSequences

    delete data.conceptResults.null;
    data.order = _.keys(incorrectSequences).length;
    const url = match.url.replace('/new', '')
    const callback = () => {
      history.push(url)
    }
    dispatch(actionFile.submitNewIncorrectSequence(match.params.questionID, data, callback));
  }

  render() {
    const { fillInBlank, generatedIncorrectSequences, match, sentenceFragments, questions, } = this.props;
    const { used } = generatedIncorrectSequences;
    const { params } = match;
    const { questionID } = params;
    return (
      <div>
        <IncorrectSequencesInputAndConceptSelectorForm
          fillInBlank={fillInBlank}
          itemLabel='Incorrect Sequence'
          onSubmit={this.submitSequenceForm}
          questionID={questionID}
          questions={questions}
          ResponseComponent={ResponseComponent}
          sentenceFragments={sentenceFragments}
          states
          usedSequences={used[questionID]}
        />
      </div>
    );
  }
}

function select(props) {
  return {
    fillInBlank: props.fillInBlank,
    questions: props.questions,
    generatedIncorrectSequences: props.generatedIncorrectSequences,
    sentenceFragments: props.sentenceFragments,
    states: props.states
  };
}

export default connect(select)(NewIncorrectSequencesContainer);
