import * as React from "react";
import ReactHtmlParser from 'react-html-parser';
import { useQuery, useQueryClient, } from 'react-query';

import { BECAUSE, BUT, SO, TITLE } from "../../../../../constants/evidence";
import { DropdownInput, Input, Spinner, } from '../../../../Shared/index';
import { quillCloseX, renderHeader } from "../../../helpers/evidence/renderHelpers";
import { createSeedData, fetchActivity } from '../../../utils/evidence/activityAPIs';
import SubmissionModal from '../shared/submissionModal';

const SeedDataForm = ({ history, match }) => {
  const { params } = match;
  const { activityId } = params;
  const [errorOrSuccessMessage, setErrorOrSuccessMessage] = React.useState<string>(null);
  const [errors, setErrors] = React.useState<string[]>([]);
  const [showSubmissionModal, setShowSubmissionModal] = React.useState<boolean>(false);

  const trueString = 'true';
  const falseString = 'false';

  const [usePassage, setUsePassage] = React.useState<string>(trueString);
  const queryClient = useQueryClient();

  const runOptions = [
    { value: trueString, label: 'Full Run'},
    { value: falseString, label: 'Label Examples Only'},
  ];

  const [activityNouns, setActivityNouns] = React.useState<string>('');

  const blankLabelConfig = { label: '', examples: ['','',''], };
  const blankLabelConfigs = { [BECAUSE] : [], [BUT] : [], [SO] : [], };

  const [labelConfigs, setLabelConfigs] = React.useState({...blankLabelConfigs});

  function handleUsePassageChange(runOption) {
    setUsePassage(runOption.value);
  };

  function handleLabelConfigsChange(event, index, conjunction, key) {
    const data = {...labelConfigs}
    const conjunctionData = [...data[conjunction]];

    conjunctionData[index][key] = event.target.value;
    data[conjunction] = conjunctionData;

    setLabelConfigs(data);
  }

  function handleExampleChange(event, index, conjunction, exampleIndex) {
    const data = {...labelConfigs}
    const conjunctionData = [...data[conjunction]];

    conjunctionData[index].examples[exampleIndex] = event.target.value;
    data[conjunction] = conjunctionData;

    setLabelConfigs(data)
  }

  function removeExample(conjunction, index, exampleIndex) {
    const data = {...labelConfigs}
    const exampleData = data[conjunction][index].examples

    exampleData.splice(exampleIndex, 1)
    data[conjunction][index].examples = exampleData

    setLabelConfigs(data)
  }

  function onAddExample(e) {
    const { target } = e;
    const { id, value } = target;
    addExample(value, id);
  }

  function addExample(conjunction, index) {
    const data = {...labelConfigs}

    data[conjunction][index].examples.push('')
    setLabelConfigs(data)
  }

  function onAddLabelConfigs(e) {
    const { target } = e;
    const { value } = target;
    addLabelConfigs(value);
  }

  function addLabelConfigs(conjunction) {
    const data = {...labelConfigs}
    const conjunctionData = [...data[conjunction], {...blankLabelConfig}];

    data[conjunction] = conjunctionData
    setLabelConfigs(data)
  }

  function onRemoveLabelConfig(e) {
    const { target } = e;
    const { id, value } = target;
    removeLabelConfig(id, value);
  }

  function removeLabelConfig(index, conjunction) {
    const data = {...labelConfigs}
    const conjunctionData = [...data[conjunction]]

    conjunctionData.splice(index, 1)
    data[conjunction] = conjunctionData

    setLabelConfigs(data)
  }

  const { data: activityData } = useQuery({
    queryKey: [`activity-${activityId}`, activityId],
    queryFn: fetchActivity
  });

  function handleCreateSeedData() {
    if (!confirm('⚠️ Are you sure you want to generate seed data?')) return

    createSeedData(activityNouns, labelConfigs, activityId, usePassage).then((response) => {
      const { errors } = response;
      if(errors && errors.length) {
        setErrors(errors);
      } else {
        setErrors([]);
        setErrorOrSuccessMessage('Seed Data started! You will receive an email with the csv files');
        setActivityNouns('');
        setUsePassage(trueString);
        setLabelConfigs({...blankLabelConfigs});
        toggleSubmissionModal();
      }
    });
  }

  function toggleSubmissionModal() { setShowSubmissionModal(!showSubmissionModal) };

  function renderSubmissionModal() {
    const message = errorOrSuccessMessage || 'Seed Data started!';
    return <SubmissionModal close={toggleSubmissionModal} message={message} />;
  }

  if(!activityId || !activityData) {
    return(
      <div className="loading-spinner-container">
        <Spinner />
      </div>
    );
  }

  function renderExample(value, index, conjunction, exampleIndex) {
    return (
      <div className='example-container'>
        <Input
          className="example-input"
          handleChange={e => handleExampleChange(e, index, conjunction, exampleIndex)}
          label={`Example ${exampleIndex + 1}`}
          value={value}
        />
        <button
          className='x-button'
          onClick={() => removeExample(conjunction, index, exampleIndex)}
        >
          <img alt="quill-circle-checkmark" src={quillCloseX} />
        </button>
      </div>
    );
  }

  function renderLabelConfig(labelConfig, index, conjunction) {
    return (
      <div className="seed-label-form" key={index}>
        <button
          className='right quill-button-archived fun secondary outlined'
          id={index}
          onClick={onRemoveLabelConfig}
          value={conjunction}
        >
          Remove
        </button>
        <div>
          <Input
            className="label-input"
            handleChange={e => handleLabelConfigsChange(e, index, conjunction, 'label')}
            label='Label'
            value={labelConfig.label}
          />
        </div>
        {labelConfig.examples.map((example, exampleIndex) => renderExample(example, index, conjunction, exampleIndex))}
        <button
          className='quill-button-archived fun secondary outlined'
          id={index}
          onClick={onAddExample}
          value={conjunction}
        >
          <span className='plus'>+</span>

          &nbsp;Add Example
        </button>
      </div>
    );
  }

  function renderLabelSection(conjunction) {
    const capitalizeConjunction = conjunction.charAt(0).toUpperCase() + conjunction.substring(1)
    return (
      <div className='label-section'>
        <h4 className='bg-quill-teal label-title'>
          <span className='highlight'>{capitalizeConjunction}</span>
          &nbsp;Label Examples
        </h4>
        {labelConfigs[conjunction].map((labelConfig, index) => renderLabelConfig(labelConfig, index, conjunction))}
        <button
          className='quill-button-archived small primary outlined'
          onClick={onAddLabelConfigs}
          value={conjunction}
        >
          <span className='plus'>+</span>

          &nbsp;Add {capitalizeConjunction} Label
        </button>
      </div>
    );
  }

  const { activity } = activityData

  return(
    <div className="seed-data-form-container">
      {showSubmissionModal && renderSubmissionModal()}
      {activity && renderHeader({activity: activity}, 'Create Seed Data', true)}
      <h4>{activity && activity.title}</h4>
      <p><b>Seed Data will be generated for each of these prompts:</b></p>
      <ul>
        {activity && activity.prompts.map((prompt, i) => <li key={i}>{prompt.text}</li>)}
      </ul>
      <details>
        <summary className="quill-button-archived fun primary outlined focus-on-light">Toggle Passage</summary>
        <br />
        <div className="passage">{ReactHtmlParser(activity && activity.passages[0].text)}</div>
      </details>
      <Input
        className="notes-input"
        error={errors[TITLE]}
        handleChange={e => setActivityNouns(e.target.value)}
        label="Optional: Noun list comma separated"
        value={activityNouns}
      />

      {renderLabelSection(BECAUSE)}
      {renderLabelSection(BUT)}
      {renderLabelSection(SO)}
      <br />
      <div className='run-type-dropdown'>
        <DropdownInput
          handleChange={handleUsePassageChange}
          isSearchable={false}
          label="Run Type"
          options={runOptions}
          value={runOptions.find(ro => ro.value === usePassage)}
        />
      </div>
      <br />
      <div className="button-and-id-container">
        <button className="quill-button-archived fun large primary contained focus-on-light" id="activity-submit-button" onClick={handleCreateSeedData} type="submit">
          <span aria-label="robot" role="img">🤖</span>
          <span aria-label="sunflower" role="img">🌻</span>

          Create Seed Data
        </button>
      </div>
      <br />
    </div>
  );
}

export default SeedDataForm;
