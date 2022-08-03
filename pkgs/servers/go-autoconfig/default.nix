{ buildGoModule
, fetchFromGitHub
, lib
}:

buildGoModule rec {
  pname = "go-autoconfig";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "L11R";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-LxipXtgMgJ4BAMINLjql7Qa0Ruj97ESEN6ZkU5zLRNc=";
  };

  # Update project dependencies
  patches = [ ./add_gosum.patch ];

  vendorSha256 = "sha256-8g4OuWrxZK5bCQc+QyuvT6VPsWEiozC4RglFnlejoAQ=";

  meta = with lib; {
    description = "IMAP/SMTP autodiscover feature for Thunderbird, Apple Mail and Microsoft Outlook";
    homepage = "https://github.com/L11R/go-autoconfig";
    license = licenses.mit;
    maintainers = with maintainers; [ onny ];
  };
}
