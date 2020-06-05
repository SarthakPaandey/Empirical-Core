import * as React from 'react';
import { shallow } from 'enzyme';
import { DataTable } from 'quill-component-library/dist/componentLibrary';
import RuleSets from '../configureRegex/ruleSets';
import 'whatwg-fetch';

const mockProps = {
  match: {
    params: {
      activityId: 1
    }
  }
}

describe('RuleSets component', () => {
  const container = shallow(<RuleSets {...mockProps} />);

  it('should render RuleSets', () => {
    expect(container).toMatchSnapshot();
  });

  it('should render a DataTable component', () => {
    expect(container.find(DataTable).length).toEqual(1);
  });
});