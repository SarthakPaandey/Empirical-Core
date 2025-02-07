import React from 'react';
import { BrowserRouter, Redirect, Route, Switch } from 'react-router-dom';
import { CompatRouter } from "react-router-dom-v5-compat";

import ActivityType from '../components/assignment_flow/create_unit/activity_type.tsx';
import AssignADiagnostic from '../components/assignment_flow/create_unit/assign_a_diagnostic.tsx';
import AssignANewActivity from '../components/assignment_flow/create_unit/assign_a_new_activity';
import AssignAp from '../components/assignment_flow/create_unit/assign_ap.tsx';
import AssignPreAp from '../components/assignment_flow/create_unit/assign_pre_ap.tsx';
import AssignSpringBoard from '../components/assignment_flow/create_unit/assign_springboard.tsx';
import CollegeBoard from '../components/assignment_flow/create_unit/college_board.tsx';
import CreateUnit from '../components/assignment_flow/create_unit/create_unit';
import UnitTemplateAssigned from '../components/assignment_flow/unit_template_assigned';
import UnitTemplateProfile from '../components/assignment_flow/unit_templates_manager/unit_template_profile/unit_template_profile.tsx';
import UnitTemplatesManager from '../components/assignment_flow/unit_templates_manager/unit_templates_manager';
import AssignActivitiesContainer from './AssignActivitiesContainer.jsx';

const AssignActivitiesRouter = props => (
  <BrowserRouter>
    <CompatRouter>
      <Route component={AssignActivitiesContainer} path="/assign" />
      <Switch>
        <Route component={routerProps => <ActivityType {...props} {...routerProps} />} path="/assign/activity-type" />
        <Route component={routerProps => <AssignPreAp {...props} {...routerProps} />} path="/assign/pre-ap" />
        <Route component={routerProps => <AssignAp {...props} {...routerProps} />} path="/assign/ap" />
        <Route component={routerProps => <AssignSpringBoard {...props} {...routerProps} />} path="/assign/springboard" />
        <Route component={routerProps => <CollegeBoard {...props} {...routerProps} />} path="/assign/college-board" />
        <Route component={routerProps => <AssignADiagnostic {...props} {...routerProps} />} path="/assign/diagnostic" />
        <Route component={routerProps => <CreateUnit {...props} {...routerProps} />} path="/assign/activity-library" />
        <Route component={routerProps => <CreateUnit {...props} {...routerProps} />} path="/assign/select-classes" />
        <Route component={routerProps => <CreateUnit {...props} {...routerProps} />} path="/assign/referral" />
        <Route component={routerProps => <CreateUnit {...props} {...routerProps} />} path="/assign/add-students" />
        <Route component={routerProps => <CreateUnit {...props} {...routerProps} />} path="/assign/next" />
        <Route component={UnitTemplateAssigned} path="/assign/featured-activity-packs/:activityPackId/assigned" />
        <Route component={UnitTemplateProfile} path="/assign/featured-activity-packs/:activityPackId" />
        <Route component={UnitTemplatesManager} path="/assign/featured-activity-packs" />
        <Redirect from="/assign/featured-activity-packs/category/:category" to="/assign/featured-activity-packs" />
        <Redirect from="/assign/featured-activity-packs/grade/:grade" to="/assign/featured-activity-packs" />
        <Route component={routerProps => <CreateUnit {...props} {...routerProps} />} path="/assign/new_unit/students/edit/name/:unitName/activity_ids/:activityIdsArray" />
        <Route component={routerProps => <AssignANewActivity {...props} {...routerProps} />} path="/assign" />
      </Switch>
    </CompatRouter>
  </BrowserRouter>
);

export default AssignActivitiesRouter
