import * as React from "react" ;
import { render, screen, }  from "@testing-library/react";
import userEvent from '@testing-library/user-event'

import { schools, canvasIntegration, } from './data'

import CanvasIntegrationContainer from '../container'

describe('CanvasIntegrationContainer', () => {

  describe('when there are existing Canvas integrations', () => {
    test('it should render', () => {
      const { asFragment } = render(<CanvasIntegrationContainer passedCanvasIntegrations={[canvasIntegration]} passedSchools={schools} />);
      expect(asFragment()).toMatchSnapshot();
    })

    test('clicking the Add New Canvas Integration button should open the new integration form', async () => {
      render(<CanvasIntegrationContainer passedCanvasIntegrations={[canvasIntegration]} passedSchools={schools} />)
      const user = userEvent.setup()

      expect(screen.queryByRole('form', {name: /new canvas integration/i})).not.toBeInTheDocument()
      await user.click(screen.getByRole('button', { name: /add new canvas integration$/i }))
      expect(screen.getByRole('form', {name: /new canvas integration/i})).toBeTruthy()
    })
  })

  describe('when there are not existing Canvas integrations', () => {
    test('it should render', () => {
      const { asFragment } = render(<CanvasIntegrationContainer passedCanvasIntegrations={[]} passedSchools={schools} />);
      expect(asFragment()).toMatchSnapshot();
    })
  })

})