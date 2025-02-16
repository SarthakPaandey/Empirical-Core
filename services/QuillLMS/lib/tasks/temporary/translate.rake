# frozen_string_literal: true

namespace :translate do
  desc 'translate hints (concept feedback)'
  desc 'on zsh use `noglob rake translate:hints[es-la]` or whatever language code you choose'
  task :hints, [:locale] => :environment do |t, args|
    locale = args[:locale] || Translatable::DEFAULT_LOCALE
    hints = ConceptFeedback.all
    count = hints.count
    hints.each_with_index do |hint, index|
      puts "translating #{index + 1}/#{count}..."
      OpenAI::TranslateWorker.perform_async(hint.id, hint.class.name, locale)
    end
  end

  desc 'translate activities and their questions'
  desc 'on zsh use `noglob rake translate:activities[es-la, 2]`'
  desc 'first param is locale, second is (optional) number of activities to translate'
  task :activities, [:locale, :limit] => :environment do |t, args|
    puts "translating activities"
    limit = args[:limit] ? args[:limit].to_i : nil
    locale = args[:locale] || Translatable::DEFAULT_LOCALE

    activities = Activity.where(uid: activity_uids).limit(limit)
    activity_count = activities.count
    activities.each_with_index do |activity, index|
      puts ''
      puts "translating #{activity.uid} #{index + 1}/#{activity_count}..."
      OpenAI::TranslateWorker.perform_async(activity.id, activity.class.name, locale)

      questions = activity.questions
      question_count = questions.count
      questions.each_with_index do |question, q_index|
        puts "translating #{question.id} question #{q_index + 1} / #{question_count}... "
        OpenAI::TranslateWorker.perform_async(question.id, question.class.name, locale)
      end
    end
  end

  desc 'translate hard-coded feedback_strings'
  task :feedback_strings, [:locale] => :environment do |t, args|
    locale = args[:locale] || Translatable::DEFAULT_LOCALE
    prompt = TranslationPrompts.feedback_strings_prompt(locale:)
    english_text = feedback_data
    result = OpenAI::Translate.run(english_text:, prompt:)
    filename = "#{fileroot}.#{locale}.#{fileformat}"
    puts result
    File.write(Rails.root.join(filefolder, 'translations', filename), result)
  end

  def fileroot = 'feedback_strings'
  def fileformat = 'json'
  def filefolder = 'config/locales'

  def feedback_data
    file_path = Rails.root.join(filefolder, "#{fileroot}.#{fileformat}")
    File.read(file_path)
  end

  def activity_uids
    %w(
      -LsTRP0gFdy-d5lIfifn
      22409f4f-c2d7-4b10-84c9-3fd046eb9a41
      -LuZ7PvG10DtLrdJDPvw
      -LuZ-V1tMCsRo56xccmi
      -LuYfZ1NrGcjyvmWLzI1
      b5b4f6bc-c5de-4f88-8374-fa8bc8b8f3af
      4f287ef0-c96e-48f1-8ef3-42bc6dcca7bf
      bb35dc9b-55a0-46a7-b2ec-93360ce2c95a
      ff2d6d79-0068-448d-bd94-738b96e79fb6
      -LuYVU0Atduong8PZryz
      e587d2e6-7ba6-4052-9f1b-7c44530c1234
      -Lv2lhvP7KwrlRcJLJi3
      b7c7d6da-1c82-4dd2-a24d-656538da96cd
      -Lv2xuPmlyeYeOsIYzT5
      b53e6ce9-109d-4d4c-bce9-2b8de0fed29f
      -Lv2n_omDvTJjuuTmXp6
      bde76ab9-d05a-484b-938a-7edcce510043
      -Lv2p_C07SJLoaMzUEla
      de20b80f-c6bd-4ed1-826a-44baaa1693a8
      4411f863-b802-4ec4-98f2-f8748ed0aca3
      ba585fdf-64d0-4544-a671-9cc9e8f8b3a0
      98068c36-a363-4c01-bd5d-9dfb599ccc4c
      7beeaeff-3c88-4ac4-bf4f-a8e3f349dbb5
      40d0c053-61ae-4964-bc30-8693f75718a6
      1c9b319a-d8f4-412f-9cec-70e5881c936b
      eecd3f79-4833-4d44-ad2f-39aad645256d
      9c3438e8-b9d7-4f5f-b361-5213a1744c30
      e84e6e71-761c-4e99-84f4-9b694959a800
      8a15d78b-dd9c-4303-b801-47ef65f18629
      8b86c18d-5d0c-4f12-b666-d5a813ad43c0
      -LuZu3a1OcHsZwlagiBp
      d716d88b-ff3d-41e3-a6f9-0edf20ad1725
      -LuZw4uebj3V-TzIGmUA
      98f80284-5cc4-4aed-bd1d-2bc196e3cab8
      -LuZv4QWPjVEwzykwKs5
      -LuEOsF2XhqpOFBF4FHa
      -LuETUQs89RfMLxhiCMu
      -LuZsFfWkRzwjDIq6WXI
      9275c2ad-8dba-4d3b-815b-0ea90edbb95f
      fec77c02-1ded-481e-ac67-b9f80052384b
      0e8ceff2-0baa-40e6-b7a3-782d78508063
      a4b8a32c-fb37-491b-844d-6eeed10f56b1
      1a998715-5254-48c1-93e3-c7e2e3abe172
      7a5788b8-5caa-4820-8a66-6b018056a06d
      d7055fdc-70cd-4bea-a4e3-eea473f5d7a2
      0fabb8fc-e279-47d4-8efb-6811f042667a
      95b0c551-e86f-493d-8a4a-1c0a4c01ed69
      04b69042-684c-4cd5-8f12-f9c7754a9249
      557d8d27-cba1-4b6e-8737-a4914cd03efb
      26345423-5cc8-4129-af9c-4bd65eb20deb
      6611032f-fded-422f-a62a-342bfbe87965
      -Lv2rJsczDdRgG0zIoGY
      b6d78908-fb6f-44aa-89fa-6d47d01ecae4
      -Lv2tZFJ2Iwk9f7Hm2lB
      -Lv2v7iQSIsnKSFa5Y5A
      f32d7ccf-30f8-4e56-b0c4-32dcb03dd8c9
      1d56961b-84a1-46db-95d0-69fd58db5446
      bf5d49de-8d3e-4015-8bd6-d380b9c4eee2
      b74d9033-4b3e-430a-a60e-ae7029190af7
      bbae8d98-8556-44f5-954a-ccf84c8f746a
      405a059f-e5ee-4919-9004-b8256f0ad0b3
      33990bb2-c9f2-4a34-bd0a-b7d8423efb90
      a4d94eac-3455-4b3c-87f7-cbfc1d4c8e32
      2b1fed6d-4826-4710-b367-39a342704bfb
      aca11f56-e4f4-486d-9e24-88920538e8f7
      16783fe0-ce02-4620-bdb9-9f2aa4d8d33d
      983aea73-6d63-4177-abe5-97fea82b7526
      57c36b85-69f8-4884-964b-85781cb4010e
      96d3dfd8-693b-48cf-853c-eab18342b467
      7b4ef773-3198-483b-8dd9-ef11721d67c7
      39a8fc88-3547-465f-b753-51c9cac75547
      70879ae9-0dcb-4245-a2f4-28a08583a97f
      1dc0d2e2-2f1d-42de-9ec2-5d58314a646d
      c64709da-4dd0-4d26-b686-1b8ec00cf105
      2e7317a7-ecd5-42ff-899a-c4deacc6e0a5
      b08cdc32-e6ba-44a3-ae50-c1f009ce243c
      e7717656-e75c-4a1b-ab18-7263aff7366f
      41acdeb5-db6f-4f5e-92b4-fc29d12b15d2
      9c7ee0ff-1aca-41ba-a279-51b52d1c6e0d
      c92d70c2-0bb6-4fce-a03b-9b0de0fbb5a3
      dc026f4d-5e22-42ee-aa5e-dea42d9a7cba
      f86cc2e9-00ea-4a62-bf49-55f7342c798c
      cd7706a2-6cad-4c65-b251-93f88a831ebf
      fc35f047-e351-4442-85a6-9498c60066b8
      f6e42dc0-08e9-4996-a7b7-41aceeac14df
      e750c52b-75e5-43be-9862-224422658559
      38b9a8e0-b7e8-480c-9b65-8bd74d8f5864
      4507698d-ca0f-4ac8-b18a-e18a48bc9608
      a35ad15e-1de6-403b-8cdc-28b724d162bf
      4fb9c065-0d21-4d36-9e8d-312626a94d05
      1d84bbee-33e3-44b1-932c-48a7c138e698
      0544e592-e260-427f-83d8-b06905a0fc85
      f42fe858-94a2-417f-8073-ce50bbccb84a
      e0fe6dd3-a1bf-4fc6-b87e-4a9b776ea56d
      dc0f7506-8a49-4169-a993-a131737c5bd3
      049db58e-4d1f-44d6-a2be-f66538bc01fe
      f812fe92-b7b3-49e8-9ca1-3b708bfdb158
      91972792-1266-4201-8a75-16f4d310a477
      e16aa67d-eacb-493b-9bcd-c8c3789f61e8
      da3aa240-674c-4354-a040-13d818507c6d
      50092c59-e693-4429-84c7-c7b120c3895c
      e881d265-a051-4cec-b6b7-3d5da207a391
      cd0cddfa-7c4e-4597-951b-6e1cfbc75803
      dacb3d2c-139d-41c7-a70c-7afb2dfd1ded
      bc024e7b-9fae-4e6a-97b5-ab056da1d146
      26afc3e5-4213-45d5-a56f-7f30f0fc757d
      50ac3b16-e5bd-4ea4-99d2-ee77fba77e00
      8aabe702-a0d0-4e1c-a9f5-e576aa1a2ce3
      cca7d6a3-09de-4b5b-86a4-bdaf43bd760e
      78876180-9b07-4087-8159-e8ae008e1b0d
      fdb5bfb7-3c22-4601-979f-12a948fe1e30
      a255774b-63f3-450d-8095-59efef0bc43c
      2905081e-3ee3-42d7-9d00-7cc840f93ec7
      8a2cb878-6f8e-48e4-9a45-95b89b1cd590
      33b402e2-8dac-43c3-b110-ecbc8bf24829
      b842f16b-83a6-43ce-b549-7d7c3c2cebc0
      35f57cbb-d51d-49f9-98c5-8bdaf4927820
      892b84d2-4809-4a19-a346-b3910036a4d9
      1b6736f9-95ed-4e41-bb77-2911329bc589
      2846b9d3-6cf2-4dbd-a93c-f8365e2fc009
      92f30aad-4061-43c7-9326-dad7d4cbc849
      708fb7fd-baa8-4995-aeca-05baf1175011
      0e25a407-8a1c-483b-b988-564d481500d4
      dc287e94-f26c-4862-abdf-e9c077480224
      f18d6449-5e54-4a43-a29f-1f5a4453f409
      e2dda12b-1097-450c-9213-4f44b6de08e3
      546961e2-f55b-44f9-bfe3-464cf2d2ceb6
      eaeb7e5a-897b-49cb-ab64-307a1999fe7f
      abb1291c-e150-4819-ad79-19277ba1eb60
      51b94d97-0255-4898-8530-1776d979ff4b
      -Lu97wyu68tDnTFDlvKd
      b8f6d4fc-42f1-416b-b1b2-c55c6cd999c9
      -LsXUzyf8l2DSp1ykK4e
      -Lt5m4PQzv4_VT2IvV4u
      09809aad-e971-4ab0-a961-846f3808709e
      -LsXcgv4qkHQT_f5AJsO
      -LuZBfG1Z9LkmIpXX1Vu
      -LuZ0jXW-HvCcJdmAH36
      -LuYgjxPCkUBjjiR8BLq
      -LuYWj-C8a0uGvhLDH-m
      853a6fb7-76d8-4e0a-8b5d-40de908545fc
      -Lv2wj-YryL4TayVbe7Q
      8052c184-3b58-4c7d-bfeb-95fd3686f403
      9ca6c169-aece-4423-b21b-1d6a0ed202d3
      be5cdac8-f58d-4ff6-b929-84172cf48ee3
      d535ad77-e1a3-44d5-8b55-1fea2be057dd
      -Lv2zLlKJFjeBI30SKW5
      -Lv36NvAz9Emt_7chIkP
      -Lv330j4II8KfXXSUUec
      14466352-5932-45af-a087-72b1d1cad166
      -Lt5jbwYDjEvVnuAc0RW
      8fdaae0b-f8d2-4469-ade0-b90f252154ee
      -Lv1shFvLJfWQMfx7Pi-
      -LyV8AlbzNy0iMcp2THL
      -LsTR00-mxGVtd4ARKTH
      -LsXPuyHm_WInovUKm-R
      4e5410f7-08ed-4ede-9daa-fbbe69115d73
      -Lt5qSGblXSuxhj0rBYo
      -LyV6TBeZMZ_LI--84X7
      208dbd40-d178-45ba-8852-6b62b9c870b8
      -Lv1u1yIS4P5xYeLGGGu
      534ffcd8-b4bb-41a1-b02e-7c41ea3ac272
      -LsIaNoUKQT3DQFqRpx5
      -LsO4DwSlWo-10HhY3_F
      -LsIg6Q8sOLH3v3jFilE
      -LsT11Ql6PMVicofrSwv
      6be73165-6d38-4493-bde7-6e31fe550724
      2a0e1374-93b8-45f1-ad7e-badf19c8301b
      -Ly_e7fHShT85TFgyM41
      -Ly_fbt8C91Qxx7_-Cli
      7d5a13c7-b8d1-4595-b46f-7dade96bad47
      -LuZkr3AmRK3jHHOWgR_
      -LuZm5v7TFkCGFgTCSxg
      b36bab88-7765-4c37-b1f6-4c70137d30e6
      -LuZne6q09tolm1mZvvo
      -LuYjArO2x6f3dakn2M4
      -LuYzGy4q504cSLhY75g
      2f4add53-3e8d-40c1-9210-0dc4b18ecc23
      -Ly_VWfkVFcYCV7i8rqx
      -Ly_ZOZq9z0vza65NTln
      0a111165-4b11-4038-af44-6702416a3014
      -LuZ2gFa20gDD09Kre_-
      -LuZ5cqJ7iNRY_2QdOck
      d09cc27b-2796-4936-b1d9-35dbe1cf089b
      -LuZoWmlAj-k7nGiP1cR
      -LuEjBXuHVfdv1WKtaeW
      -LuYZlNkpF0DeX_qqF0O
      21336014-29eb-4073-b2f7-f1a93b3ecf60
      a55db845-bc57-4adf-9cec-f05cc3b829d9
      cf86cdf4-2be0-4a07-ada6-19275f48ae81
      -Lv37eSrw3QrBHV7xEjR
      46579fa3-06b3-4f73-a343-7704a149440a
      -Lya402C0JqeEtGjvWR8
      a6818914-ba97-45e0-8102-3ffdff398825
      8f090abb-4c7b-46c9-a946-faad8ea5ab60
      455ff11c-ef27-4d69-a25a-ca2fc33014d9
      -Lu9nuipMB_KS3FwQV4U
      -LuYeX9fN-m9_DKGRjy6
      -Lu9m4PS_-6vKEz8FDnb
      -LuEU3kku-L-ntxujrPC
      d7b21b9e-8c87-42dd-8c90-4dd12216d956
      bce76de2-6150-4a8d-bee9-7be60b56e04b
      -LuEUc9mA5SQwmETdQ_N
      -Lt5nddxIQuWgb3ayJWJ
      31a37b03-85bb-4dac-8ed2-eccb637e211b
      -LuZqTIbKXRGK60SJ7zS
      02a23694-3c9c-448c-9c94-1bc9dac7c49c
      u5RZdiz_yIOQpC97mrUILQ
      -L5AkM2UkdLULttcvWg-
      -LM3rorg-oBJra8KXGbK
      9bbdf783-47a3-415d-8c51-a8578dbc869b
      a479cb3b-c861-4425-87af-48d669c7fb48
      1b8c6890-8789-405b-a0bd-24ec115edcff
      f0edc7f0-9dac-435a-89af-888a55123354
      e6236c89-904a-4b37-bcf8-a376dcc669cf
      badc48a2-0b9a-425c-8604-6f55d7ee6620
      908627da-b82d-4e4f-b588-079d1368601f
      3212f239-0ec1-4618-872a-c4513f0bae80
      b66b116d-a4d3-4594-a854-bf35fdedeb13
      e0cd4e4e-4200-4718-84e5-8a2505ea0f7b
      589dab5b-597f-45a4-8e14-9835f60fd8ca
      4411f863-b802-4ec4-98f2-f8748ed0aca3
      0e31db06-df4c-46f1-85cd-1f0afad9ae7a
      -KybO7eiRjMiMYYowjtR
      Gy6gKsETtSsIafZHLkPxUA
      83KWWwB6tOWV7mnw82GHaQ
      a6e46fc4-1330-42e6-8919-5a37c049258c
      55798cd1-f873-471c-b271-de5942755b26
      c206f3cf-ef74-42ed-a084-be9285f8822e
      f9f13b90-c781-47ad-adc3-1ef7d58dc7a4
      30b6460c-8c60-4a4f-be96-69bf51b80f07
      7e923287-652f-401f-b12e-df9bd13242ac
      c03657c5-2123-476d-8687-39a133cdfd46
      480d46c0-f42f-44cb-b388-d6016d4ef46f
      c5397ec0-16a9-47e2-89ee-c23d4dd4d7fe
      z8WSMBEV9uBRodWd_t-RNA
      34a7b5ed-4e72-45b9-9903-223a6b0cc512
      150f3ff3-5eca-4321-8518-adbd4e37238c
      985cb32b-9023-4bc7-b9ad-17f6c0013ebe
      11d8c9d8-d348-4811-8382-e284ae6fd548
      -KybNc1Xkj1Yz59OoNaA
      96febf0a-bc98-49dc-8f33-d8e14dcf96dd
      694d62c9-507d-4d4e-9a92-2c406405059e
      afb71b57-d396-448e-ba47-1682db197efa
      39c036e7-3054-4e37-80a2-b456406ef4ca
      ed4c4213-a152-4150-8c3f-5a3c645e533f
      7465938b-1aa8-4aa0-a490-219c5d603540
      72f6df8e-6ce1-464e-b13f-8462e42c337a
      -KCNHR8NB8GFBmLLXcdu
      8d717fa8-4de8-4bea-9533-bce8d31a338e
      -L0udJg9M0ETmF6k0zJ6
      14b067b6-9c67-4ebc-86f1-6b0d0aca489f
      c3666d96-f8b0-401c-80e3-e44e36595866
      62688a3e-c46d-4464-9076-50a355bc4058
      QdR3olOK3n2Wz6tMgTKmHQ
      b2adfc26-e170-43a9-8dc8-abf07b57dac4
      a2d0fef8-8d96-4f98-bf02-099afdcf96f8
      -LM37tB4K_a-nnIqSPDJ
      23558883-3b27-40ca-ac30-6b559fa0692f
      bf6b07e4-7cc5-4017-8f62-04c522af57ad
      373c71a3-c498-4cfd-9a95-7eff7a707e6f
      6079b59b-f8e3-4cc4-8fd4-babe543ddf0e
      -LJVfDfTAZ45WfBuusDf
      4cb1ab15-6d3a-4cd2-a7e5-525c25647f48
      7b4ef773-3198-483b-8dd9-ef11721d67c7
      7b4ef773-3198-483b-8dd9-ef11721d67c7
      811a485c-e2fa-4eaf-bb35-bc59575657ec
      f4db2a4b-88b4-496b-a046-0dd493aa8d40
      -L6NxywB46cJRo_HvN-0
      -L0R1JR_TZuGM3QT1dHs
      30bf1d2d-50ec-4452-b85f-0df1f3d63418
      h3sGPjz1IkIgl3ODIozsUg
      -L6JG-2GOXst7gMZJkDS
      7reO3f_OIauga8bopw14HA
      03b8bbc9-947a-4dec-a661-b850d031137f
      827f5dbd-493f-470b-90ed-60cf9dcdd0b7
      e316f28e-bbc3-4167-bb5b-d57ea2a90dc3
      76260b20-4807-42a3-93f4-28dccef3e9f2
      c848c1ce-0a90-45f8-8a92-10a2bef42973
      398f8b32-c082-4929-8d82-e74390b339b1
      40F3qnu3khw2ooEw2oZwLQ
      72c938f8-ac9f-45dc-9eeb-8cab93f85dc7
      ae5fd428-0922-47f8-b9f8-c98679f1b4f1
      8f401c3f-4f75-4141-a41d-42d5643e7f72
    )
  end
end
