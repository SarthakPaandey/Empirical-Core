import * as React from "react";
import { renderRoutes } from "react-router-config";
import { useQuery } from 'react-query';

import Header from "./Header";

import { fetchUserRole } from '../../Shared/utils/userAPIs';
import { ScreenreaderInstructions, TeacherPreviewMenu, INTRODUCTION } from '../../Shared/index';
import { routes } from "../routes";
import getParameterByName from '../helpers/getParameterByName';

const PageLayout = (props: any) => {
  const { user } = props;
  const turkSession = getParameterByName('turk', window.location.href);
  const isPlaying = window.location.href.includes('play');
  const { data } = useQuery("user-role", fetchUserRole);
  const isTeacherOrAdmin = data && data.role && data.role !== 'student';

  const [previewShowing, setPreviewShowing] = React.useState<boolean>(false);
  const [questionToPreview, setQuestionToPreview] = React.useState<any>(INTRODUCTION);

  React.useEffect(() => {
    if(isTeacherOrAdmin && !turkSession) {
      setPreviewShowing(true)
    }
  }, [isTeacherOrAdmin])

  function handleSkipToMainContentClick () {
    const element = document.getElementById("main-content")
    if (!element) { return }
    element.focus()
    element.scrollIntoView()
  }

  function handleTogglePreviewMenu() {
    setPreviewShowing(!previewShowing);
  }

  function handleToggleQuestion(step: string) {
    setQuestionToPreview(step);
  }

  const showPreview = previewShowing && isTeacherOrAdmin && isPlaying;
  const contentClass = showPreview ? 'evidence-preview-mode' : '';
  const isOnMobile = window.innerWidth < 1100;

  return (
    <div className="app-container">
      <ScreenreaderInstructions />
      <button className="skip-main" onClick={handleSkipToMainContentClick} type="button">Skip to main content</button>
      <Header isOnMobile={isOnMobile} isTeacher={isTeacherOrAdmin} onTogglePreview={handleTogglePreviewMenu} previewShowing={showPreview} />
      <div className="activity-container">
        {showPreview && <aside
          className="sider-container"
          style={{ overflowY: 'auto', width: '360px' }}
        >
          <TeacherPreviewMenu
            isOnMobile={isOnMobile}
            onTogglePreview={handleTogglePreviewMenu}
            onToggleQuestion={handleToggleQuestion}
            questionToPreview={questionToPreview}
            showPreview={previewShowing}
          />
        </aside>}
        <div className={contentClass} id="main-content" tabIndex={-1}>{renderRoutes(routes, {
          user,
          previewMode: showPreview
        })}</div>
      </div>
    </div>
  );
};

export default PageLayout;
