# frozen_string_literal: true

require 'rails_helper'

describe Cms::DistrictsController do
  let(:user) { create(:staff) }

  before { allow(controller).to receive(:current_user) { user } }

  it { should use_before_action :text_search_inputs }
  it { should use_before_action :set_district }

  describe 'DISTRICTS_PER_PAGE' do
    it 'should have the correct value' do
      expect(described_class::DISTRICTS_PER_PAGE).to eq 30.0
    end
  end

  describe '#index' do
    let(:district_hash) { { district_zip: '1234', district_name: 'Test District', district_city: 'Test City' } }

    it 'should allows staff memeber to view and search through district' do
      get :index
      expect(assigns(:district_search_query)).to eq({})
      expect(assigns(:district_search_query_results)).to eq []
      expect(assigns(:number_of_pages)).to eq 0
    end

    it 'should assign the correct default values' do
      get :index
      expect(assigns(:district_premium_types)).to match_array(Subscription::OFFICIAL_DISTRICT_TYPES)
    end
  end

  describe '#search' do
    let!(:district) { create(:district, name: 'Test District') }
    let!(:subscription) { create(:subscription, account_type: Subscription::OFFICIAL_DISTRICT_TYPES.first) }
    let(:district_hash) do
      {
        id: district.id,
        name: district.name,
        nces_id: district.nces_id,
        city: district.city,
        state: district.state,
        zipcode: district.zipcode,
        phone: district.phone,
        premium_status: district.subscription.account_type,
        total_students: district.total_students,
        total_schools: district.total_schools
      }
    end

    it 'should search for the district and give the results' do
      create(:district_subscription, district: district, subscription: subscription)
      get :search, params: { :district_name => 'test' }
      expect(JSON.parse(response.body).deep_symbolize_keys)
        .to eq({ numberOfPages: 1, districtSearchQueryResults: [district_hash] })
    end

    context 'user sorts the search results by premium status' do
      it 'should display the results in sort order with the correct direction' do
        create(:district_subscription, district: district, subscription: subscription)
        district_without_subscription = create(:district)

        get :search, params: { :sort => 'premium_status', :sort_direction => 'desc' }
        expect(JSON.parse(response.body)['districtSearchQueryResults'][0]['id']).to eq(district_without_subscription.id)
        expect(JSON.parse(response.body)['districtSearchQueryResults'][1]['id']).to eq(district.id)
      end
    end
  end

  describe '#show' do
    let!(:district) { create(:district) }
    let!(:subscription) { create(:subscription, account_type: Subscription::OFFICIAL_DISTRICT_TYPES.first) }

    it 'should assign the correct values' do
      create(:district_subscription, district: district, subscription: subscription)
      get :show, params: { id: district.id }
      expect(assigns(:district)).to eq(district)
      expect(assigns(:school_data)).to eq([])
      expect(assigns(:admins)).to eq(DistrictAdmin.includes(:user).where(district_id: district.id).map do |admin|
        {
          name: admin.user.name,
          email: admin.user.email,
          district_id: admin.district_id,
          user_id: admin.user_id
        }
      end)
      expect(assigns(:district_subscription_info)).to eq({
        'District Premium Type' => district.subscription.account_type,
        'Expiration' => district.subscription.expiration.strftime('%b %d, %Y')
      })
    end

    context 'when the district has schools with some expired subscriptions' do
      it 'should show only one record of each school' do
        school = create(:school, district: district)
        expired_sub = create(:subscription, expiration: 15.days.ago.to_date)
        active_sub = create(:subscription)
        create(:school_subscription, school: school, subscription: expired_sub)
        create(:school_subscription, school: school, subscription: active_sub)

        get :show, params: { id: district.id }
        expect(assigns(:school_data)[0]).to eq(school)
        expect(assigns(:school_data).length).to eq(1)
      end

      it 'should show a record if the only subscription is expired' do
        school = create(:school, district: district)
        expired_sub = create(:subscription, expiration: 15.days.ago.to_date)
        create(:school_subscription, school: school, subscription: expired_sub)

        get :show, params: { id: district.id }
        expect(assigns(:school_data)[0]).to eq(school)
        expect(assigns(:school_data).length).to eq(1)
      end
    end
  end

  describe '#edit' do
    let!(:district) { create(:district) }

    it 'should assign the district and editable attributes' do
      get :edit, params: { id: district.id }
      expect(assigns(:district)).to eq district
      expect(assigns(:editable_attributes)).to eq({
        'District Name' => :name,
        'District City' => :city,
        'District State' => :state,
        'District ZIP' => :zipcode,
        'District Phone' => :phone,
        'NCES ID' => :nces_id,
        'Clever ID' => :clever_id,
        'Total Schools' => :total_schools,
        'Total Students' => :total_students,
        'Grade Range' => :grade_range
      })
    end
  end

  describe '#update' do
    let!(:district) { create(:district) }

    it 'should update the given district' do
      post :update, params: { id: district.id, district: { id: district.id, name: 'test name' } }
      expect(district.reload.name).to eq 'test name'
      expect(response).to redirect_to cms_district_path(district.id)
    end
  end

  describe '#new_admin' do
    let!(:district) { create(:district) }

    it 'should assign the district' do
      get :new_admin, params: { id: district.id }
      expect(assigns(:district)).to eq district
    end
  end

  describe '#create' do
    it 'does not create, returns an error message if district NCES ID is not unique' do
      existing_district = create(:district)

      post :create, params: { district: existing_district.as_json }
      expect(response).to redirect_to cms_districts_path
      expect(flash[:error].first).to include('A district with this NCES ID already exists.')
    end
  end

  describe '#edit_subscription' do
    let!(:district) { create(:district_subscription).district }

    it 'should assign the subscription' do
      get :edit_subscription, params: { id: district.id }

      expect(assigns(:subscription)).to eq district.subscription
    end
  end

  describe '#new_subscription' do
    let!(:district) { create(:district) }
    let!(:subscription) { create(:subscription) }
    let!(:district_subscription) { create(:district_subscription, district: district, subscription: subscription) }
    let!(:district_with_no_subscription) { create(:district) }

    describe 'when there is no existing subscription' do
      it 'should create a new subscription that starts today and ends at the promotional expiration date' do
        get :new_subscription, params: { id: district_with_no_subscription.id }
        expect(assigns(:subscription).start_date).to eq Date.current
        expect(assigns(:subscription).expiration).to eq Subscription.promotional_dates[:expiration]
      end
    end

    describe 'when there is an existing subscription' do
      it 'should create a new subscription with starting after the current subscription ends' do
        get :new_subscription, params: { id: district.id }
        expect(assigns(:subscription).start_date).to eq subscription.expiration
        expect(assigns(:subscription).expiration).to eq subscription.expiration + 1.year
      end
    end
  end
end
