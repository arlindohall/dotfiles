{
  ast = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "10yknjyn0728gjn6b5syynvrvrwm66bhssbxq8mkhshxghaiailm";
      type = "gem";
    };
    version = "2.4.3";
  };
  benchmark = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1kicilpma5l0lwayqjb5577bm0hbjndj2gh150xz09xsgc1l1vyl";
      type = "gem";
    };
    version = "0.4.1";
  };
  coderay = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0jvxqxzply1lwp7ysn94zjhh57vc14mcshw1ygw14ib8lhc00lyw";
      type = "gem";
    };
    version = "1.1.3";
  };
  erubi = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1naaxsqkv5b3vklab5sbb9sdpszrjzlfsbqpy7ncbnw510xi10m0";
      type = "gem";
    };
    version = "1.13.1";
  };
  json = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1x5b8ipv6g0z44wgc45039k04smsyf95h2m5m67mqq35sa5a955s";
      type = "gem";
    };
    version = "2.12.2";
  };
  language_server-protocol = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1k0311vah76kg5m6zr7wmkwyk5p2f9d9hyckjpn3xgr83ajkj7px";
      type = "gem";
    };
    version = "3.17.0.5";
  };
  lint_roller = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "11yc0d84hsnlvx8cpk4cbj6a4dz9pk0r1k29p0n1fz9acddq831c";
      type = "gem";
    };
    version = "1.1.0";
  };
  logger = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "00q2zznygpbls8asz5knjvvj2brr3ghmqxgr83xnrdj4rk3xwvhr";
      type = "gem";
    };
    version = "1.7.0";
  };
  method_source = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1igmc3sq9ay90f8xjvfnswd1dybj1s3fi0dwd53inwsvqk4h24qq";
      type = "gem";
    };
    version = "1.1.0";
  };
  netrc = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0gzfmcywp1da8nzfqsql2zqi648mfnx6qwkig3cv36n9m0yy676y";
      type = "gem";
    };
    version = "0.11.0";
  };
  nokogiri = {
    dependencies = ["racc"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "jHRkh12cp/cQgMJMDbe8qjlA6L48b8S868z4uaABY2U=";
      type = "gem";
    };
    version = "1.18.8";
  };
  parallel = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0c719bfgcszqvk9z47w2p8j2wkz5y35k48ywwas5yxbbh3hm3haa";
      type = "gem";
    };
    version = "1.27.0";
  };
  parser = {
    dependencies = ["ast" "racc"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0i9w8msil4snx5w11ix9b0wf52vjc3r49khy3ddgl1xk890kcxi4";
      type = "gem";
    };
    version = "3.3.8.0";
  };
  prism = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0gkhpdjib9zi9i27vd9djrxiwjia03cijmd6q8yj2q1ix403w3nw";
      type = "gem";
    };
    version = "1.4.0";
  };
  pry = {
    dependencies = ["coderay" "method_source"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0ssv704qg75mwlyagdfr9xxbzn1ziyqgzm0x474jkynk8234pm8j";
      type = "gem";
    };
    version = "0.15.2";
  };
  racc = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0byn0c9nkahsl93y9ln5bysq4j31q8xkf2ws42swighxd4lnjzsa";
      type = "gem";
    };
    version = "1.8.1";
  };
  rainbow = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0smwg4mii0fm38pyb5fddbmrdpifwv22zv3d3px2xx497am93503";
      type = "gem";
    };
    version = "3.1.1";
  };
  rbi = {
    dependencies = ["prism" "rbs" "sorbet-runtime"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0f0l9g63c3q8qc7w0v5z5778w0f4dlni1w74g9qncj0kzprrkkbh";
      type = "gem";
    };
    version = "0.3.3";
  };
  rbs = {
    dependencies = ["logger"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1mx533jn2nv29xc5faw9g5xj9qbdaiwl9wv2byv98bgw6gqwhhlf";
      type = "gem";
    };
    version = "3.9.4";
  };
  regexp_parser = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0qccah61pjvzyyg6mrp27w27dlv6vxlbznzipxjcswl7x3fhsvyb";
      type = "gem";
    };
    version = "2.10.0";
  };
  rexml = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1jmbf6lf7pcyacpb939xjjpn1f84c3nw83dy3p1lwjx0l2ljfif7";
      type = "gem";
    };
    version = "3.4.1";
  };
  rubocop = {
    dependencies = ["json" "language_server-protocol" "lint_roller" "parallel" "parser" "rainbow" "regexp_parser" "rubocop-ast" "ruby-progressbar" "unicode-display_width"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "04f4a6c735rd7k5h63vx7fj7wnd37j9jki70wfvkq2r8w6c56ldp";
      type = "gem";
    };
    version = "1.76.0";
  };
  rubocop-ast = {
    dependencies = ["parser" "prism"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1mvqdzqbifs49vhjb9ffmhb56kqnk3x45yqlfbhbj9azs5vxwjhb";
      type = "gem";
    };
    version = "1.45.0";
  };
  ruby-lsp = {
    dependencies = ["language_server-protocol" "prism" "rbs" "sorbet-runtime"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "12ng3mxss04xkclq8xgm1037c853p5rpar45k5iczi3ih4zxiw0i";
      type = "gem";
    };
    version = "0.24.0";
  };
  ruby-progressbar = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0cwvyb7j47m7wihpfaq7rc47zwwx9k4v7iqd9s1xch5nm53rrz40";
      type = "gem";
    };
    version = "1.13.0";
  };
  sorbet = {
    dependencies = ["sorbet-static"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1kmdkhrmpb43g9skxgwf4xyh6ajrf2a0ihyj4xdw1zmqcdkckfv4";
      type = "gem";
    };
    version = "0.5.12157";
  };
  sorbet-runtime = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "094jqwg321v79g6i6f6rmd64zi4jlvhyvqghky3b4cxljm77i7yx";
      type = "gem";
    };
    version = "0.5.12157";
  };
  sorbet-static = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0i507fyzd58d9l6rb2682xbdzrh5jqilidjrsw04i3gxxi55zlfg";
      type = "gem";
    };
    version = "0.5.12157";
  };
  sorbet-static-and-runtime = {
    dependencies = ["sorbet" "sorbet-runtime"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "15fwpmw7f9bazy2wyl72hz2bq7zrx3c0sjk3xqhjy9hamlpx75p5";
      type = "gem";
    };
    version = "0.5.12157";
  };
  spoom = {
    dependencies = ["erubi" "prism" "rbi" "rexml" "sorbet-static-and-runtime" "thor"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0lyi479sdk883azs21fd0lpfj054s3y86x9mfp5y78j3lq0sa18d";
      type = "gem";
    };
    version = "1.6.3";
  };
  tapioca = {
    dependencies = ["benchmark" "netrc" "parallel" "rbi" "sorbet-static-and-runtime" "spoom" "thor" "yard-sorbet"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1xxi3rxvq40zpicsm9nmlijrpddcq9xza96dh24fy8i0bs53isxy";
      type = "gem";
    };
    version = "0.16.11";
  };
  thor = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1nmymd86a0vb39pzj2cwv57avdrl6pl3lf5bsz58q594kqxjkw7f";
      type = "gem";
    };
    version = "1.3.2";
  };
  unicode-display_width = {
    dependencies = ["unicode-emoji"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1has87asspm6m9wgqas8ghhhwyf2i1yqrqgrkv47xw7jq3qjmbwc";
      type = "gem";
    };
    version = "3.1.4";
  };
  unicode-emoji = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0ajk6rngypm3chvl6r0vwv36q1931fjqaqhjjya81rakygvlwb1c";
      type = "gem";
    };
    version = "4.0.4";
  };
  yard = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "14k9lb9a60r9z2zcqg08by9iljrrgjxdkbd91gw17rkqkqwi1sd6";
      type = "gem";
    };
    version = "0.9.37";
  };
  yard-sorbet = {
    dependencies = ["sorbet-runtime" "yard"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "08gy7xr94znrgsbd4f92hp8z9z097sm176lihsw8574y3d3aml83";
      type = "gem";
    };
    version = "0.9.0";
  };
}
