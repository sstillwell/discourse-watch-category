# name: Watch Category
# about: Watches a category for all the users in a particular group
# version: 0.3
# authors: Arpit Jalan
# url: https://github.com/discourse/discourse-watch-category-mcneel


module ::WatchCategory

  def self.watch_category!
    groups_cats = {
      # "group" => ["category", "another-top-level-category", ["parent-category", "sub-category"] ],
      # "everyone" makes every user watch the listed categories
      # "everyone" => [ "announcements" ]
      "coordinating-cmte" => [ ["private", "coordinating-committee"] ],
      "digcol-cmte" => [ ["private", "digital-collections-committee"] ],
      "digped-cmte" => [ ["private", "digital-pedagogy-committee"] ],
      "digschol-cmte" => [ ["private", "digital-scholarship-committee"] ],
      "eresources-cmte" => [ ["private", "e-resources-committee"], ["private", "buyers-group"] ],
      "infolit-cmte" => [ ["private", "information-literacy-committee"] ],
      "inst-research-cmte" => [ ["private", "institutional-research-assessment-committee"] ],
      "oclc-cmte" => [ ["private", "oclc-programs-committee"] ],
      "profdev-cmte" => [ ["private", "professional-development-committee"] ],
      "grant-review-cmte" => [ ["private", "grant-review-cmte"] ],
      "amical-2018-joint-org" => [ ["private", "amical-2018-joint-org"] ],
      "amical-2018-program-cmte" => [ ["private", "amical-2018-program-cmte"] ],
      "amical-2019-joint-org" => [ ["private", "amical-2019-joint-org"] ],
      "amical-2019-program-cmte" => [ ["private", "amical-2019-program-cmte"] ],
      "amical-2020-joint-org" => [ ["private", "amical-2020-joint-org"] ],
      "amical-2020-program-org" => [ ["private", "amical-2020-program-org"] ],
      "dhsi-2018-cohort" => [ ["private", "dhsi-2018-cohort"] ],
      "dhi-b-2019-cohort" => [ ["private", "dhi-b-2019-cohort"] ],
      "chairs" => [ ["private", "chairs"] ],
      "facdevcenters" => [ ["private", "facdevcenters"] ]
    }
    WatchCategory.change_notification_pref_for_group(groups_cats, :watching)

    groups_cats = {
      "infolit" => [ ["interest-groups", "information-literacy"] ],
      "pedagogy" => [ ["interest-groups", "pedagogy"] ],
      "amical-2019" => [ ["interest-groups", "amical-2019"] ],
      "open-source-library-systems" => [ ["interest-groups", "open-source-library-systems"] ],
      "digital-literacy" => [ ["interest-groups", "digital-literacy"] ],
      "coordinating-cmte" => [ "announcements" ],
      "representatives" => [ "announcements" ],
      "lib-buyers" => [ ["private", "buyers-group"] ]
    }
    WatchCategory.change_notification_pref_for_group(groups_cats, :watching_first_post)
  end

  def self.change_notification_pref_for_group(groups_cats, pref)
    groups_cats.each do |group_name, cats|
      cats.each do |cat_slug|

        # If a category is an array, the first value is treated as the top-level category and the second as the sub-category
        if cat_slug.respond_to?(:each)
          category = Category.find_by_slug(cat_slug[1], cat_slug[0])
        else
          category = Category.find_by_slug(cat_slug)
        end
        group = Group.find_by_name(group_name)

        unless category.nil? || group.nil?
          if group_name == "everyone"
            User.all.each do |user|
              watched_categories = CategoryUser.lookup(user, pref).pluck(:category_id)
              CategoryUser.set_notification_level_for_category(user, CategoryUser.notification_levels[pref], category.id) unless watched_categories.include?(category.id)
            end
          else
            group.users.each do |user|
              watched_categories = CategoryUser.lookup(user, pref).pluck(:category_id)
              CategoryUser.set_notification_level_for_category(user, CategoryUser.notification_levels[pref], category.id) unless watched_categories.include?(category.id)
            end
          end
        end

      end
    end
  end

end

after_initialize do
  module ::WatchCategory
    class WatchCategoryJob < ::Jobs::Scheduled
      every 1.hours

      def execute(args)
        WatchCategory.watch_category!
      end
    end
  end
end
