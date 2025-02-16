# frozen_string_literal: true

require 'rails_helper'

describe TeacherCenterHelper do
  describe '#teacher_center_tabs' do
    let(:current_user) { create(:teacher) }
    let(:app_setting) { create(:app_setting, name: 'comprehension') }
    let(:tabs) {
      [
        { id: BlogPost::ALL_RESOURCES, name: BlogPost::ALL_RESOURCES, url: '/teacher-center' },
        { id: BlogPost::WHATS_NEW, name: BlogPost::WHATS_NEW, url: '/teacher-center/topic/whats-new' },
        { id: BlogPost::WRITING_FOR_LEARNING, name: BlogPost::WRITING_FOR_LEARNING, url: '/teacher-center/topic/writing-for-learning' },
        { id: BlogPost::GETTING_STARTED, name: BlogPost::GETTING_STARTED, url: '/teacher-center/topic/getting-started' },
        { id: BlogPost::BEST_PRACTICES, name: BlogPost::BEST_PRACTICES, url: '/teacher-center/topic/best-practices' },
        { id: BlogPost::WRITING_INSTRUCTION_RESEARCH, name: BlogPost::WRITING_INSTRUCTION_RESEARCH, url: '/teacher-center/topic/writing-instruction-research' },
        { id: TeacherCenterHelper::FAQ, name: TeacherCenterHelper::FAQ, url: '/faq' },
        { id: BlogPost::WEBINARS, name: BlogPost::WEBINARS, url: '/teacher-center/topic/webinars' },
        { id: BlogPost::TEACHER_MATERIALS, name: BlogPost::TEACHER_MATERIALS, url: '/teacher-center/topic/teacher-materials' },
        { id: BlogPost::TEACHER_STORIES, name: BlogPost::TEACHER_STORIES, url: '/teacher-center/topic/teacher-stories' }
      ]
    }

    it 'should return the expected tabs' do
      expect(helper.teacher_center_tabs).to eq tabs
    end
  end

  describe `#explore_curriculum_tabs` do
    let(:tabs) {
      [
        { id: 'Featured Activities', name: 'Featured Activities', url: '/activities/packs' },
        { id: 'AP Activities', name: 'AP Activities', url: '/ap' },
        { id: 'Pre-AP Activities', name: 'Pre-AP Activities', url: '/preap' },
        { id: 'SpringBoard Activities', name: 'SpringBoard Activities', url: '/springboard' },
        { id: 'ELA Standards', name: 'ELA Standards', url: '/activities/standard_level/7' }
      ]
    }

    it 'should return the expected tabs' do
      expect(helper.explore_curriculum_tabs).to eq tabs
    end
  end
end
