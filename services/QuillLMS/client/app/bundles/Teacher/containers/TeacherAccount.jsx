import React from 'react';

import { requestPost, requestPut, } from '../../../modules/request/index';
import { Snackbar, defaultSnackbarTimeout } from '../../Shared/index';
import TeacherDangerZone from '../components/accounts/edit/teacher_danger_zone';
import TeacherEmailNotifications from '../components/accounts/edit/teacher_email_notifications';
import TeacherGeneralAccountInfo from '../components/accounts/edit/teacher_general';
import TeacherGradeLevels from '../components/accounts/edit/teacher_grade_levels';
import TeacherLinkedAccounts from '../components/accounts/edit/teacher_linked_accounts';
import TeacherSubjectAreas from '../components/accounts/edit/teacher_subject_areas';
import TeacherPasswordAccountInfo from '../components/accounts/edit/update_password';
import TeacherStudentDashboardSettings from '../components/accounts/edit/teacher_student_dashboard_settings'

function gradeLevelToOption(gradeLevel) {
  return gradeLevel ? { value: gradeLevel, label: gradeLevel, } : null
}

const PASSWORD = 'password'
const GRADE_LEVEL = 'gradeLevel'
const SUBJECT_AREAS = 'subjectAreas'
const GENERAL = 'general'
const EMAIL_NOTIFICATIONS = 'emailNotifications'
const STUDENT_DASHBOARD_SETTINGS = 'studentDashboardSettings'

export default class TeacherAccount extends React.Component {
  constructor(props) {
    super(props)

    const {
      name,
      email,
      clever_id,
      google_id,
      time_zone,
      school,
      school_type,
      send_newsletter,
      notification_email_frequency,
      teacher_notification_settings,
      minimum_grade_level,
      maximum_grade_level,
      subject_area_ids,
      show_students_exact_score,
    } = props.accountInfo
    this.state = {
      activeSection: null,
      name,
      email,
      timeZone: time_zone,
      school,
      schoolType: school_type,
      googleId: google_id,
      cleverId: clever_id,
      sendNewsletter: send_newsletter,
      tempSendNewsletter: send_newsletter,
      notificationEmailFrequency: notification_email_frequency,
      tempNotificationEmailFrequency: notification_email_frequency,
      teacherNotificationSettings: teacher_notification_settings,
      tempTeacherNotificationSettings: teacher_notification_settings,
      minimumGradeLevel: minimum_grade_level,
      maximumGradeLevel: maximum_grade_level,
      selectedSubjectAreaIds: subject_area_ids,
      showStudentsExactScore: show_students_exact_score,
      snackbarCopy: '',
      showSnackbar: false,
      errors: {},
      timesSubmitted: 0,
    }
  }

  UNSAFE_componentWillMount() {
    let snackbarCopy
    const { googleOrCleverJustSet, accountInfo, } = this.props
    if (googleOrCleverJustSet) {
      if (accountInfo.google_id) {
        snackbarCopy = 'Google linked'
      }
      if (accountInfo.clever_id) {
        snackbarCopy = 'Clever linked'
      }
      this.setState({ snackbarCopy, }, this.showSnackbar)
    }
  }

  setTeacherNotificationOption = (key, value) => {
    this.setState({[key]: value})
  }

  resetTeacherNotificationSection = () => {
    const { sendNewsletter, notificationEmailFrequency, teacherNotificationSettings } = this.state

    this.setState({
      "tempSendNewsletter": sendNewsletter,
      "tempNotificationEmailFrequency": notificationEmailFrequency,
      "tempTeacherNotificationSettings": teacherNotificationSettings
    })
  }

  activateSection = section => {
    this.setState({ activeSection: section, })
  };

  deactivateSection = section => {
    const { activeSection } = this.state
    if (activeSection === section) {
      this.setState({ activeSection: null, errors: {}, })
    }
  };

  deleteAccount = () => {
    const { accountInfo } = this.props
    const { id, } = accountInfo

    requestPost(
      `${process.env.DEFAULT_URL}/teachers/clear_data/${id}`,
      {},
      () => window.location.href = window.location.origin
    )
  };

  showSnackbar = () => {
    this.setState({ showSnackbar: true, }, () => {
      setTimeout(() => this.setState({ showSnackbar: false, }), defaultSnackbarTimeout)
    })
  };

  updateTeacherInfo = (data, snackbarCopy) => {
    requestPut(
      '/teacher_infos',
      data,
      (body) => {
        const {
          minimum_grade_level,
          maximum_grade_level,
          subject_area_ids,
          notification_email_frequency,
          show_students_exact_score,
        } = body

        this.setState({
          minimumGradeLevel: minimum_grade_level,
          maximumGradeLevel: maximum_grade_level,
          selectedSubjectAreaIds: subject_area_ids,
          notificationEmailFrequency: notification_email_frequency,
          tempNotificationEmailFrequency: notification_email_frequency,
          showStudentsExactScore: show_students_exact_score,
          snackbarCopy,
          errors: {}
        }, () => {
          if (snackbarCopy) { this.showSnackbar() }
          this.setState({ activeSection: null, })
        })
      },
      (body) => {
        this.setState({ errors: body.errors, timesSubmitted: timesSubmitted + 1, })
      }
    )
  }

  updateNotificationSettings = (data) => {
    requestPost(
      '/api/v1/teacher_notification_settings/bulk_update',
      data,
      (body) => {
        const { teacher_notification_settings, } = body
        this.setState({
          teacherNotificationSettings: teacher_notification_settings,
          tempTeacherNotificationSettings: teacher_notification_settings,
          errors: {}
        }, () => {
          this.setState({activeSection: null, })
        })
      },
      (body) => {
        this.setState({ errors: body.errors, timesSubmitted: timesSubmitted + 1, })
      }
    )
  }

  updateUser = (data, url, snackbarCopy) => {
    const { timesSubmitted, } = this.state
    requestPut(
      `${process.env.DEFAULT_URL}${url}`,
      data,
      (body) => {
        const {
          name,
          email,
          clever_id,
          google_id,
          time_zone,
          school,
          school_type,
          send_newsletter,
        } = body
        this.setState({
          name,
          email,
          timeZone: time_zone,
          school,
          schoolType: school_type,
          googleId: google_id,
          cleverId: clever_id,
          sendNewsletter: send_newsletter,
          tempSendNewsletter: send_newsletter,
          snackbarCopy,
          errors: {}
        }, () => {
          this.showSnackbar()
          this.setState({ activeSection: null, })
        })
      },
      (body) => {
        this.setState({ errors: body.errors, timesSubmitted: timesSubmitted + 1, })
      }
    )
  };

  renderSnackbar = () => {
    const { showSnackbar, snackbarCopy, } = this.state
    return <Snackbar text={snackbarCopy} visible={showSnackbar} />
  };

  render() {
    const {
      name,
      email,
      cleverId,
      googleId,
      timeZone,
      school,
      schoolType,
      errors,
      timesSubmitted,
      activeSection,
      tempSendNewsletter,
      tempNotificationEmailFrequency,
      tempTeacherNotificationSettings,
      postGoogleClassroomAssignments,
      minimumGradeLevel,
      maximumGradeLevel,
      selectedSubjectAreaIds,
      showStudentsExactScore,
    } = this.state

    const { accountInfo, alternativeSchools, alternativeSchoolsNameMap, cleverLink, showDismissSchoolSelectionReminderCheckbox, subjectAreas, } = this.props
    return (
      <div className="user-account white-background-accommodate-footer">
        <TeacherGeneralAccountInfo
          activateSection={() => this.activateSection(GENERAL)}
          active={activeSection === GENERAL}
          alternativeSchools={alternativeSchools}
          alternativeSchoolsNameMap={alternativeSchoolsNameMap}
          cleverId={cleverId}
          deactivateSection={() => this.deactivateSection(GENERAL)}
          email={email}
          errors={errors}
          googleId={googleId}
          name={name}
          school={school}
          schoolType={schoolType}
          showDismissSchoolSelectionReminderCheckbox={showDismissSchoolSelectionReminderCheckbox}
          timesSubmitted={timesSubmitted}
          timeZone={timeZone}
          updateUser={this.updateUser}
        />
        <TeacherPasswordAccountInfo
          activateSection={() => this.activateSection(PASSWORD)}
          active={activeSection === PASSWORD}
          cleverId={cleverId}
          deactivateSection={() => this.deactivateSection(PASSWORD)}
          errors={errors}
          googleId={googleId}
          role={accountInfo.role}
          timesSubmitted={timesSubmitted}
          updateUser={this.updateUser}
        />
        <TeacherLinkedAccounts
          cleverId={cleverId}
          cleverLink={cleverLink}
          email={email}
          errors={errors}
          googleId={googleId}
          postGoogleClassroomAssignments={postGoogleClassroomAssignments}
          timesSubmitted={timesSubmitted}
          updateUser={this.updateUser}
        />
        <TeacherEmailNotifications
          activateSection={() => this.activateSection(EMAIL_NOTIFICATIONS)}
          active={activeSection === EMAIL_NOTIFICATIONS}
          deactivateSection={() => this.deactivateSection(EMAIL_NOTIFICATIONS)}
          notificationEmailFrequency={tempNotificationEmailFrequency}
          notificationSettings={tempTeacherNotificationSettings}
          resetTeacherNotificationSection={this.resetTeacherNotificationSection}
          sendNewsletter={tempSendNewsletter}
          setTeacherNotificationOption={this.setTeacherNotificationOption}
          updateNotificationSettings={this.updateNotificationSettings}
          updateTeacherInfo={this.updateTeacherInfo}
          updateUser={this.updateUser}
        />
        <TeacherGradeLevels
          activateSection={() => this.activateSection(GRADE_LEVEL)}
          active={activeSection === GRADE_LEVEL}
          deactivateSection={() => this.deactivateSection(GRADE_LEVEL)}
          passedMaximumGradeLevel={gradeLevelToOption(maximumGradeLevel)}
          passedMinimumGradeLevel={gradeLevelToOption(minimumGradeLevel)}
          updateTeacherInfo={this.updateTeacherInfo}
        />
        <TeacherSubjectAreas
          activateSection={() => this.activateSection(SUBJECT_AREAS)}
          active={activeSection === SUBJECT_AREAS}
          deactivateSection={() => this.deactivateSection(SUBJECT_AREAS)}
          passedSelectedSubjectAreaIds={selectedSubjectAreaIds}
          subjectAreas={subjectAreas}
          updateTeacherInfo={this.updateTeacherInfo}
        />
        <TeacherStudentDashboardSettings
          activateSection={() => this.activateSection(STUDENT_DASHBOARD_SETTINGS)}
          active={activeSection === STUDENT_DASHBOARD_SETTINGS}
          deactivateSection={() => this.deactivateSection(STUDENT_DASHBOARD_SETTINGS)}
          passedShowStudentsExactScore={showStudentsExactScore}
          updateTeacherInfo={this.updateTeacherInfo}
        />
        <TeacherDangerZone
          deleteAccount={this.deleteAccount}
        />
        {this.renderSnackbar()}
      </div>
    )
  }
}
