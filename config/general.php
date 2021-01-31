<?php
/**
 * General Configuration
 *
 * All of your system's general configuration settings go in here. You can see a
 * list of the available settings in vendor/craftcms/cms/src/config/GeneralConfig.php.
 *
 * @see \craft\config\GeneralConfig
 */

use craft\helpers\App;

return [
    // Global settings
    '*' => [
        // Any custom Yii aliases (opens new window) that should be defined for every request.
        'aliases' => [
            '@assetsUrl' => App::env('ASSETS_URL'),
            '@web' => App::env('SITE_URL'),
            '@webroot' => App::env('WEB_ROOT_PATH'),
        ],
        // The default length of time Craft will store data, RSS feed, and template caches.
        'cacheDuration' => false,
        // Control panel trigger word
        'cpTrigger' => 'admin',
        // The default options that should be applied to each search term.
        'defaultSearchTermOptions' => [
            'subLeft' => true,
            'subRight' => true,
        ],
        // The default amount of time tokens can be used before expiring.
        'defaultTokenDuration' => 'P2W',
        // Default Week Start Day (0 = Sunday, 1 = Monday...)
        'defaultWeekStartDay' => 1,
        // Whether to enable CSRF protection via hidden form inputs for all forms submitted via Craft.
        'enableCsrfProtection' => true,
        // The prefix that should be prepended to HTTP error status codes when determining the path to look for an error’s template.
        'errorTemplatePrefix' => 'errors/',
        // Whether image transforms should be generated before page load.
        'generateTransformsBeforePageLoad' => true,
        // The maximum dimension size to use when caching images from external sources to use in transforms. Set to 0 to never cache them.
        'maxCachedCloudImageSize' => 3000,
        // The maximum upload file size allowed.
        'maxUploadFileSize' => '100M',
        // Whether generated URLs should omit "index.php"
        'omitScriptNameInUrls' => true,
        // The path to the root directory that should store published control panel resources.
        'resourceBasePath' => App::env('WEB_ROOT_PATH').'/cpresources',
        // The secure key Craft will use for hashing and encrypting data
        'securityKey' => App::env('SECURITY_KEY'),
        // Whether Craft should set users’ usernames to their email addresses, rather than let them set their username separately.
        'useEmailAsUsername' => false,
        // Whether Craft should specify the path using PATH_INFO or as a query string parameter when generating URLs.
        'usePathInfo' => true,
        'useProjectConfigFile' => true,
    ],

    // Dev environment settings
    'dev' => [
        // Dev Mode (see https://craftcms.com/guides/what-dev-mode-does)
        'devMode' => true,
        // Whether to enable Craft’s template {% cache %} tag on a global basis.
        'enableTemplateCaching' => false,
    ],

    // Staging environment settings
    'staging' => [
        // Set this to `false` to prevent administrative changes from being made on staging
        'allowAdminChanges' => false,
        // Whether Craft should allow system and plugin updates in the control panel, and plugin installation from the Plugin Store.
        'allowUpdates' => false,
    ],

    // Production environment settings
    'production' => [
        // Set this to `false` to prevent administrative changes from being made on production
        'allowAdminChanges' => false,
        // Whether Craft should allow system and plugin updates in the control panel, and plugin installation from the Plugin Store.
        'allowUpdates' => false,
    ],
];
