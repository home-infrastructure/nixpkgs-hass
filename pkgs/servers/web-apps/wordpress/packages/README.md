= Add plugin to repository =

To add a plugin to the Wordpress plugin repository, add a new line to the
`wordpress-plugins.json` file with the codename of the plugin.

The codename is the last part in the url of the plugin page, for example
`cookie-notice` in in the url `https://wordpress.org/plugins/cookie-notice/`.

To regenerate the nixpkgs Wordpress plugin repository, run:

``` 
./generate.sh
``` 

After that you can commit and submit the changes.

= Usage with the Wordpress module =

The plugins will be available in the namespace `wordpressPackages.plugins`.
Using it together with the Wordpress module could look like this:

``` 
services.wordpress = {
  sites."blog.${config.networking.domain}" = {
    plugins = with wordpressPackages.plugins; [
      anti-spam-bee
      code-syntax-block
      cookie-notice
      lightbox-with-photoswipe
      wp-gdpr-compliance
    ];
  };
};
```
