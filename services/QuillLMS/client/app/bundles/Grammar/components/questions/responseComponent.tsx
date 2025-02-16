import * as React from 'react';
import { connect } from 'react-redux';
import _ from 'underscore';
import { requestGet, } from '../../../../modules/request/index';
import {
  QuestionBar,
  ResponseSortFields,
  ResponseToggleFields,
  Spinner,
  hashToCollection,
  responsesWithStatus,
} from '../../../Shared/index';
import * as filterActions from '../../actions/filters';
import * as massEdit from '../../actions/massEdit';
import * as questionActions from '../../actions/questions';
import {
  submitResponseEdit,
} from '../../actions/responses';
import {
  rematchAll,
  rematchOne
} from '../../libs/grading/rematching.ts';
import { getPartsOfSpeechTags } from '../../libs/partsOfSpeechTagging';
import POSForResponsesList from './POSForResponsesList';
import ResponseList from './responseList';

import { ActionTypes } from '../../actions/actionTypes';

const labels = ActionTypes.ERROR_AUTHORS;
const qualityLabels = ['Human Optimal', 'Human Sub-Optimal', 'Algorithm Optimal', 'Algorithm Sub-Optimal', 'Unmatched'];
// ["Human Optimal", "Human Sub-Optimal", "Algorithm Optimal", "Algorithm Sub-Optimal",  "Unmatched",
// "Focus Point Hint", "Word Error Hint", "Punctuation Hint", "Capitalization Hint", "Punctuation and Case Hint", "Whitespace Hint",
// "Missing Word Hint", "Additional Word Hint", "Modified Word Hint", "Missing Details Hint", "Not Concise Hint", "No Hint"]
const colors = ['#81c784', '#ffb74d', '#BA68C8', '#5171A5', '#e57373'];

const responsesPerPage = 20;

class ResponseComponent extends React.Component {
  constructor(props) {
    super(props)
    const actions = questionActions;
    this.state = {
      percentageOfWeakResponses: 0,
      actions,
      viewingResponses: true,
      selectedResponses: [],
      health: {},
      gradeBreakdown: {},
      enableRematchAllButton: true,
      isLoadingResponses: false,
    };

    this.getHealth = this.getHealth.bind(this)
    this.getGradeBreakdown = this.getGradeBreakdown.bind(this)
    this.clearResponses = this.clearResponses.bind(this)
    this.searchResponses = this.searchResponses.bind(this)
    this.getTotalAttempts = this.getTotalAttempts.bind(this)
    this.getResponseCount = this.getResponseCount.bind(this)
    this.removeResponseFromMassEditArray = this.removeResponseFromMassEditArray.bind(this)
    this.expand = this.expand.bind(this)
    this.updateRematchedResponse = this.updateRematchedResponse.bind(this)
    this.getPercentageWeakResponses = this.getPercentageWeakResponses.bind(this)
    this.getErrorsForAttempt = this.getErrorsForAttempt.bind(this)
    this.generateFeedbackString = this.generateFeedbackString.bind(this)
    this.rematchResponse = this.rematchResponse.bind(this)
    this.rematchAllResponses = this.rematchAllResponses.bind(this)
    this.responsesWithStatus = this.responsesWithStatus.bind(this)
    this.responsesGroupedByStatus = this.responsesGroupedByStatus.bind(this)
    this.responsesByStatusCodeAndResponseCount = this.responsesByStatusCodeAndResponseCount.bind(this)
    this.formatForQuestionBar = this.formatForQuestionBar.bind(this)
    this.gatherVisibleResponses = this.gatherVisibleResponses.bind(this)
    this.getResponse = this.getResponse.bind(this)
    this.getChildResponses = this.getChildResponses.bind(this)
    this.getResponsesForCurrentPage = this.getResponsesForCurrentPage.bind(this)
    this.getBoundsForCurrentPage = this.getBoundsForCurrentPage.bind(this)
    this.renderResponses = this.renderResponses.bind(this)
    this.toggleResponseSort = this.toggleResponseSort.bind(this)
    this.renderSortingFields = this.renderSortingFields.bind(this)
    this.toggleFieldAndResetPage = this.toggleFieldAndResetPage.bind(this)
    this.toggleExcludeMisspellings = this.toggleExcludeMisspellings.bind(this)
    this.resetFields = this.resetFields.bind(this)
    this.deselectFields = this.deselectFields.bind(this)
    this.renderStatusToggleMenu = this.renderStatusToggleMenu.bind(this)
    this.collapseAllResponses = this.collapseAllResponses.bind(this)
    this.expandAllResponses = this.expandAllResponses.bind(this)
    this.allClosed = this.allClosed.bind(this)
    this.renderExpandCollapseAll = this.renderExpandCollapseAll.bind(this)
    this.renderRematchAllButton = this.renderRematchAllButton.bind(this)
    this.renderPOSStrings = this.renderPOSStrings.bind(this)
    this.renderViewResponsesOrPOSButton = this.renderViewResponsesOrPOSButton.bind(this)
    this.renderResetAllFiltersButton = this.renderResetAllFiltersButton.bind(this)
    this.renderDeselectAllFiltersButton = this.renderDeselectAllFiltersButton.bind(this)
    this.getPOSTagsList = this.getPOSTagsList.bind(this)
    this.handleStringFiltering = this.handleStringFiltering.bind(this)
    this.getFilteredResponses = this.getFilteredResponses.bind(this)
    this.updatePageNumber = this.updatePageNumber.bind(this)
    this.incrementPageNumber = this.incrementPageNumber.bind(this)
    this.decrementPageNumber = this.decrementPageNumber.bind(this)
    this.getNumberOfPages = this.getNumberOfPages.bind(this)
    this.resetPageNumber = this.resetPageNumber.bind(this)
    this.renderDisplayingMessage = this.renderDisplayingMessage.bind(this)
    this.renderPageNumbers = this.renderPageNumbers.bind(this)
    this.setResponsesLoaded = this.setResponsesLoaded.bind(this)
  }

  componentDidMount() {
    this.searchResponses();
    this.getHealth();
    this.getGradeBreakdown();
    this.props.dispatch(questionActions.initializeSubscription(this.props.questionID));
  }

  componentDidUpdate(prevProps) {
    // remove text field when comparing, since sometimes the text search can change without necessarilly requiring
    // a new search (e.g when admin is typing)
    if (this.props.states && this.props.states[this.props.questionID] === ActionTypes.SHOULD_RELOAD_RESPONSES && prevProps.states[prevProps.questionID] !== ActionTypes.SHOULD_RELOAD_RESPONSES) {
      this.props.dispatch(questionActions.clearQuestionState(this.props.questionID));
      this.searchResponses();
    }
  }

  componentWillUnmount() {
    this.props.dispatch(questionActions.removeSubscription(this.props.questionID));
    this.clearResponses();
  }

  getHealth() {
    requestGet(
      `${process.env.QUILL_CMS}/questions/${this.props.questionID}/health`,
      (body) => {
        this.setState({
          health: body,
        });
      }
    )
  }

  getGradeBreakdown() {
    requestGet(
      `${process.env.QUILL_CMS}/questions/${this.props.questionID}/grade_breakdown`,
      (body) => {
        this.setState({
          gradeBreakdown: body,
        });
      }
    )
  }

  setResponsesLoaded() {
    this.setState({isLoadingResponses: false})
  }

  clearResponses() {
    this.props.dispatch(questionActions.updateResponses({ responses: [], numberOfResponses: 0, numberOfPages: 1, responsePageNumber: 1, }));
  }

  searchResponses() {
    const { questionID } = this.props

    this.setState({isLoadingResponses: true})

    this.props.dispatch(questionActions.incrementRequestCount())
    this.props.dispatch(questionActions.searchResponses(questionID, this.setResponsesLoaded))
  }

  getTotalAttempts() {
    return this.state.health.total_number_of_attempts;
    // return _.reduce(this.props.responses, (memo, item) => memo + item.count, 0);
  }

  getResponseCount() {
    return this.state.health.total_number_of_responses;
  }

  removeResponseFromMassEditArray(responseKey) {
    this.props.dispatch(massEdit.removeResponseFromMassEditArray(responseKey));
  }

  expand(responseKey) {
    this.props.dispatch(filterActions.toggleExpandSingleResponse(responseKey));
  }

  updateRematchedResponse(rid, vals) {
    this.props.dispatch(submitResponseEdit(rid, vals, this.props.questionID));
  }

  getPercentageWeakResponses() {
    const { common_unmatched_responses, total_number_of_responses } = this.state.health
    return common_unmatched_responses > 0 ? (common_unmatched_responses / total_number_of_responses * 100).toFixed(2) : 0.0
  }

  getErrorsForAttempt(attempt) {
    return attempt.feedback;
  }

  generateFeedbackString(attempt) {
    const errors = this.getErrorsForAttempt(attempt);
    // // add keys for react list elements
    // var errorComponents = _.values(_.mapObject(errors, (val, key) => {
    //   if (val) {
    //     return feedbackStrings[key]
    //   }
    // }))
    return errors;
  }

  rematchResponse(rid) {
    const response = this.props.filters.responses[rid];
    const callback = this.searchResponses;
    rematchOne(response, this.props.mode, this.props.question, this.props.questionID, callback);
  }

  rematchAllResponses() {
    this.setState({enableRematchAllButton: false});

    const pageNumber = 1;
    const callback = (done) => {
      if (done) {
        this.searchResponses();
        this.getHealth();
        this.getGradeBreakdown();
      }
    };
    const weak = rematchAll(this.props.mode, this.props.questionID, callback);
    // weak.forEach((resp, index) => {
    //   const percentage = index / weak.length * 100;
    //   this.rematchResponse(resp.key);
    // });
  }

  responsesWithStatus() {
    return hashToCollection(responsesWithStatus(this.props.filters.responses));
  }

  responsesGroupedByStatus() {
    return _.groupBy(this.responsesWithStatus(), 'statusCode');
  }

  responsesByStatusCodeAndResponseCount() {
    const responsesGroupedByStatus = this.responsesGroupedByStatus()
    return Object.keys(responsesGroupedByStatus).map(key => {
      const val = responsesGroupedByStatus[key]
      return _.reduce(val, (memo, resp) => memo + (resp.count || 0), 0)
    })
  }

  formatForQuestionBar() {
    // {"human_optimal":153,"human_suboptimal":140,"algo_optimal":0,"algo_suboptimal":8780,"unmatched":28820}
    const totalResponseCount = this.state.health.total_number_of_attempts;
    if (totalResponseCount === 0) {
      return [{
        value: 100,
        color: '#eeeeee',
      }];
    }
    return Object.keys(this.state.gradeBreakdown).map(key => {
      const val = this.state.gradeBreakdown[key]
      return {
        value: val / totalResponseCount * 100,
        color: colors[qualityLabels.indexOf(key)],
      }
    })
  }

  gatherVisibleResponses() {
    return this.responsesWithStatus();
  }

  getResponse(responseID) {
    return this.props.filters.responses[responseID];
  }

  getChildResponses(responseID) {
    const responses = hashToCollection(this.props.responses);
    return _.where(responses, { parentID: responseID, });
  }

  getResponsesForCurrentPage(responses) {
    return responses;
  }

  getBoundsForCurrentPage(length) {
    const startIndex = (this.props.filters.responsePageNumber - 1) * responsesPerPage;
    const endIndex = startIndex + responsesPerPage > length ? length : startIndex + responsesPerPage;
    return [startIndex, endIndex];
  }

  renderResponses() {
    const { isLoadingResponses, viewingResponses } = this.state

    if (isLoadingResponses && viewingResponses) {
      return (
        <div className="loading-spinner-container">
          <Spinner />
        </div>
      );
    }
    if (viewingResponses) {
      const { questionID, selectedIncorrectSequences, selectedFocusPoints } = this.props;
      const responsesWStatus = this.responsesWithStatus();
      const responses = _.sortBy(responsesWStatus, 'sortOrder');
      return (
        <ResponseList
          admin={this.props.admin}
          ascending={this.props.filters.ascending}
          conceptID={this.props.question.conceptID}
          concepts={this.props.concepts}
          conceptsFeedback={this.props.conceptsFeedback}
          dispatch={this.props.dispatch}
          expand={this.expand}
          expanded={this.props.filters.expanded}
          getChildResponses={this.getChildResponses}
          getMatchingResponse={this.rematchResponse}
          getResponse={this.getResponse}
          massEdit={this.props.massEdit}
          mode={this.props.mode}
          question={this.props.question}
          questionID={questionID}
          responses={responses}
          selectedFocusPoints={selectedFocusPoints}
          selectedIncorrectSequences={selectedIncorrectSequences}
          states={this.props.states}
        />
      );
    }
  }

  toggleResponseSort(field) {
    this.props.dispatch(filterActions.toggleResponseSort(field));
  }

  renderSortingFields() {
    return (
      <ResponseSortFields
        ascending={this.props.filters.ascending}
        sorting={this.props.filters.sorting}
        toggleResponseSort={this.toggleResponseSort}
      />
    );
  }

  toggleFieldAndResetPage(status) {
    this.props.dispatch(filterActions.toggleStatusFieldAndResetPage(status));
  }

  toggleExcludeMisspellings() {
    this.props.dispatch(filterActions.toggleExcludeMisspellings());
  }

  resetFields() {
    this.props.dispatch(filterActions.resetAllFields());
  }

  deselectFields() {
    this.props.dispatch(filterActions.deselectAllFields());
  }

  renderStatusToggleMenu() {
    const { filters } = this.props
    const { visibleStatuses } = filters
    const regexLabels = this.incorrectSequenceNames().concat(this.focusPointNames())

    return (
      <ResponseToggleFields
        deselectFields={this.deselectFields}
        excludeMisspellings={this.props.filters.formattedFilterData.filters.excludeMisspellings}
        labels={labels}
        qualityLabels={qualityLabels}
        regexLabels={regexLabels}
        resetFields={this.resetFields}
        resetPageNumber={this.resetPageNumber}
        toggleExcludeMisspellings={this.toggleExcludeMisspellings}
        toggleFieldAndResetPage={this.toggleFieldAndResetPage}
        visibleStatuses={visibleStatuses}
      />
    );
  }

  collapseAllResponses() {
    this.props.dispatch(filterActions.collapseAllResponses());
  }

  expandAllResponses() {
    const responses = this.responsesWithStatus();
    const newExpandedState = this.props.filters.expanded;
    for (const response of responses ) {
      newExpandedState[response.key] = true;
    }
    this.props.dispatch(filterActions.expandAllResponses(newExpandedState));
  }

  allClosed() {
    const expanded = this.props.filters.expanded;
    for (const i in expanded) {
      if (expanded[i] === true) { return false; }
    }
    return true;
  }

  incorrectSequenceNames = () => {
    const { question } = this.props
    const { incorrectSequences } = question

    let incorrectSequenceNames = []
    if (Array.isArray(incorrectSequences)) {
      incorrectSequenceNames = incorrectSequences.map(i => i.name)
    } else if (incorrectSequences) {
      incorrectSequenceNames = Object.keys(incorrectSequences).map((key) => incorrectSequences[key].name)
    }
    return incorrectSequenceNames.filter(f => f !== undefined)
  }

  focusPointNames = () => {
    const { question } = this.props
    const { focusPoints } = question

    let focusPointNames = []
    if (Array.isArray(focusPoints)) {
      focusPointNames = focusPoints.map(fp => fp.name)
    } else if (focusPoints) {
      focusPointNames = Object.keys(focusPoints).map((key) => focusPoints[key].name)
    }
    return focusPointNames.filter(f => f !== undefined)
  }

  renderExpandCollapseAll() {
    let text,
      handleClick;

    if (this.allClosed()) {
      handleClick = this.expandAllResponses;
      text = 'Expand';
    } else {
      handleClick = this.collapseAllResponses;
      text = 'Close';
    }
    return <a className="button is-fullwidth" onClick={handleClick}>{text}</a>;
  }

  renderRematchAllButton() {
    const { filters, admin } = this.props;
    const { progress, enableRematchAllButton } = this.state;

    if (admin) {
      const text = progress ? `${progress}%` : 'Rematch Responses';

      return (<button className="button is-outlined is-danger" disabled={!enableRematchAllButton} onClick={this.rematchAllResponses} style={{ float: 'right', }} type="button">{text}</button>);
    }
  }

  renderPOSStrings() {
    if (!this.state.viewingResponses) {
      const posTagsList = this.getResponsesForCurrentPage(hashToCollection(this.getPOSTagsList()));
      return (
        <div>
          <POSForResponsesList posTagsList={posTagsList} />
        </div>
      );
    }
  }

  renderViewResponsesOrPOSButton() {
    return (
      <div className="column">
        <button
          className="button is-fullwidth is-outlined"
          onClick={() => {
            this.setState({
              viewingResponses: !this.state.viewingResponses,
            }, this.updatePageNumber(1));
          }}
        >Show {this.state.viewingResponses ? 'POS' : 'Uniques'}</button>
      </div>
    );
  }

  renderResetAllFiltersButton() {
    return (
      <div className="column">
        <button className="button is-fullwidth is-outlined" onClick={this.resetFields}>Select All Filters</button>
      </div>
    );
  }

  renderDeselectAllFiltersButton() {
    return (
      <div className="column">
        <button className="button is-fullwidth is-outlined" onClick={this.deselectFields}>Deselect All Filters</button>
      </div>
    );
  }

  getPOSTagsList() {
    const responses = this.gatherVisibleResponses();
    const responsesWithPOSTags = responses.map((response) => {
      response.posTags = getPartsOfSpeechTags(response.text.replace(/(<([^>]+)>)/ig, '').replace(/&nbsp;/ig, '')); // some text has html tags
      return response;
    });

    const posTagsList = {}
    let posTagsAsString = '';
    responses.forEach((response) => {
      posTagsAsString = response.posTags ? response.posTags.join() : '';
      if (posTagsList[posTagsAsString]) {
        posTagsList[posTagsAsString].count += response.count;
        posTagsList[posTagsAsString].responses.push(response);
      } else {
        posTagsList[posTagsAsString] = {
          tags: response.posTags,
          count: response.count,
          responses: [
            response
          ],
        };
      }
    });
    return posTagsList;
  }

  handleStringFiltering() {
    this.props.dispatch(questionActions.updateStringFilter(this.refs.stringFilter.value, this.props.questionID));
    // this.setState({ stringFilter: this.refs.stringFilter.value, responsePageNumber: 1, }, () => this.searchResponses());
  }

  getFilteredResponses(responses) {
    if (this.props.filters.stringFilter === '') {
      return responses;
    }
    const that = this;
    return _.filter(responses, response => response.text.indexOf(that.props.filters.stringFilter) >= 0);
  }

  updatePageNumber(pageNumber) {
    this.props.dispatch(questionActions.updatePageNumber(pageNumber));
    this.searchResponses();
  }

  incrementPageNumber() {
    if (this.props.filters.responsePageNumber < this.getNumberOfPages()) {
      this.updatePageNumber(this.props.filters.responsePageNumber + 1);
    }
  }

  decrementPageNumber() {
    if (this.props.filters.responsePageNumber !== 1) {
      this.updatePageNumber(this.props.filters.responsePageNumber - 1);
    }
  }

  getNumberOfPages() {
    return this.props.filters.numberOfPages;
  }

  resetPageNumber() {
    this.updatePageNumber(1);
  }

  renderDisplayingMessage() {
    let endWord,
      length;
    if (this.state.viewingResponses) {
      length = this.props.filters.numberOfResponses;
      endWord = ' responses';
    } else {
      length = hashToCollection(this.getPOSTagsList()).length;
      endWord = ' parts of speech strings';
    }
    const bounds = this.getBoundsForCurrentPage(length);
    const message = `Displaying ${bounds[0] + 1}-${bounds[1]} of ${length}${endWord}`;
    return <p className="label">{message}</p>;
  }

  renderPageNumbers() {
    // var array
    // if(this.state.viewingResponses) {
    //   array = this.gatherVisibleResponses()
    // } else {
    //   array = this.getPOSTagsList()
    // }

    let pageNumbers = [1]

    if (this.props.filters.numberOfPages) {
      pageNumbers = _.range(1, this.props.filters.numberOfPages + 1);
    }

    let pageNumberStyle = {};
    const numbersToRender = pageNumbers.map((pageNumber, i) => {
      if (this.props.filters.responsePageNumber === pageNumber) {
        pageNumberStyle = {
          backgroundColor: 'lightblue',
        };
      } else {
        pageNumberStyle = {};
      }
      return (
        <li key={i}>
          <a className="button" onClick={() => this.updatePageNumber(pageNumber)} style={pageNumberStyle}>{pageNumber}</a>
          {/* <a className="button" style={pageNumberStyle} onClick={() => { this.setState({ responsePageNumber: pageNumber, }); }}>{pageNumber}</a> */}
        </li>
      );
    });

    let nextButtonClassName = 'button pagination-extreme-button';
    if (this.props.filters.responsePageNumber === this.getNumberOfPages()) {
      nextButtonClassName += ' is-disabled';
    }
    const nextButton = <a className={nextButtonClassName} onClick={this.incrementPageNumber}>Next</a>;

    let prevButtonClassName = 'button pagination-extreme-button';
    if (this.props.filters.responsePageNumber === 1) {
      prevButtonClassName += ' is-disabled';
    }
    const prevButton = <a className={prevButtonClassName} onClick={this.decrementPageNumber}>Prev</a>;

    return (
      <div>
        <div className="response-pagination-container">
          <nav className="pagination response-pagination">
            {prevButton}
            {nextButton}
            <ul>
              {numbersToRender}
            </ul>
          </nav>
        </div>
      </div>
    );
  }

  showResults = () => {
    this.searchResponses();
  }

  renderShowResultsButton = () => {
    return (
      <div className="show-results-container">
        <a className="button is-outlined is-primary search" onClick={this.showResults}>Show Results</a>
      </div>
    );
  }

  render() {
    const questionBar = this.props.filters.responses && Object.keys(this.props.filters.responses).length > 0
      ? <QuestionBar data={_.values(this.formatForQuestionBar())} />
      : <span />;

    return (
      <div style={{ marginTop: 0, paddingTop: 0, }}>
        {questionBar}
        {this.renderRematchAllButton()}
        <h4 className="title is-5" >
          Overview - Total Attempts: <strong>{this.getTotalAttempts()}</strong> | Unique Responses: <strong>{this.getResponseCount()}</strong> | Percentage of weak responses: <strong>{this.getPercentageWeakResponses()}%</strong>
        </h4>
        <div className="filters-and-sorting-container">
          <div className="tabs is-toggle is-fullwidth">
            {this.renderStatusToggleMenu()}
          </div>
          <div className="columns">
            <div className="column">
              <div className="tabs is-toggle is-fullwidth">
                {this.renderSortingFields()}
              </div>
            </div>
            <div className="column">
              <div className="columns">
                <div className="column">
                  {this.renderExpandCollapseAll()}
                </div>
                {this.renderResetAllFiltersButton()}
                {this.renderDeselectAllFiltersButton()}
                {this.renderViewResponsesOrPOSButton()}
              </div>
            </div>
          </div>
          <input className="input" onChange={this.handleStringFiltering} placeholder="Enter a search term or /regular expression/" ref="stringFilter" type="text" value={this.props.filters.stringFilter} />
        </div>
        {this.renderShowResultsButton()}
        {this.renderDisplayingMessage()}
        {this.renderPageNumbers()}
        {this.renderResponses()}
        {this.renderPOSStrings()}
        {this.renderPageNumbers()}
      </div>
    );
  }
}

function select(state) {
  return {
    filters: state.filters,
    conceptsFeedback: state.conceptsFeedback,
    concepts: state.concepts,
    massEdit: state.massEdit,
  };
}

export default connect(select)(ResponseComponent);
