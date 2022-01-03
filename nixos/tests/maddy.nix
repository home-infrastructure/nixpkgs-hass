let
  certs = import ./common/acme/server/snakeoil-certs.nix;
  domain = certs.domain;
in
import ./make-test-python.nix ({ pkgs, ... }: {
  name = "maddy";
  meta = with pkgs.lib.maintainers; { maintainers = [ onny ]; };

  nodes = {
    server = { ... }: {
      services.maddy = {
        enable = true;
        hostname = "server";
        primaryDomain = "server";
        openFirewall = true;
      };
    };

    servertls = { ... }: {
      services.maddy = {
        enable = true;
        hostname = "servertls";
        primaryDomain = "servertls";
        tls = {
          keyPath = "${certs.${domain}.key}";
          certPath = "${certs.${domain}.cert}";
        };
        imap.tlsEnable = true;
        submission.tlsEnable = true;
        openFirewall = true;
      };
    };

    client = { ... }: {
      environment.systemPackages = [
        (pkgs.writers.writePython3Bin "send-testmail" { } ''
          import smtplib
          from email.mime.text import MIMEText

          # Sending mail on an unencrypted submission port
          msg = MIMEText("Hello World")
          msg['Subject'] = 'Test'
          msg['From'] = "postmaster@server"
          msg['To'] = "postmaster@server"
          with smtplib.SMTP('server', 587) as smtp:
              smtp.login('postmaster@server', 'test')
              smtp.sendmail('postmaster@server', 'postmaster@server', msg.as_string())

          # Sending mail via TLS port
          msg = MIMEText("Hello World")
          msg['Subject'] = 'Test'
          msg['From'] = "postmaster@servertls"
          msg['To'] = "postmaster@servertls"
          with smtplib.SMTP('servertls', 465) as smtp:
              smtp.login('postmaster@servertls', 'test')
              smtp.sendmail('postmaster@servertls',
                            'postmaster@servertls', msg.as_string())
        '')
        (pkgs.writers.writePython3Bin "test-imap" { } ''
          import imaplib

          with imaplib.IMAP4('server') as imap:
              imap.login('postmaster@server', 'test')
              imap.select()
              status, refs = imap.search(None, 'ALL')
              assert status == 'OK'
              assert len(refs) == 1
              status, msg = imap.fetch(refs[0], 'BODY[TEXT]')
              assert status == 'OK'
              assert msg[0][1].strip() == b"Hello World"

          with imaplib.IMAP4('servertls') as imap:
              imap.login('postmaster@servertls', 'test')
              imap.select()
              status, refs = imap.search(None, 'ALL')
              assert status == 'OK'
              assert len(refs) == 1
              status, msg = imap.fetch(refs[0], 'BODY[TEXT]')
              assert status == 'OK'
              assert msg[0][1].strip() == b"Hello World"
        '')
      ];
    };
  };

  testScript = ''
    start_all()
    server.wait_for_unit("maddy.service")
    servertls.wait_for_unit("maddy.service")

    # Waiting for Imap ports
    server.wait_for_open_port(143)
    servertls.wait_for_open_port(993)

    # Waiting for Submission ports
    server.wait_for_open_port(587)
    servertls.wait_for_open_port(465)

    server.succeed("echo test | maddyctl creds create postmaster@server")
    server.succeed("maddyctl imap-acct create postmaster@server")
    servertls.succeed("echo test | maddyctl creds create postmaster@servertls")
    servertls.succeed("maddyctl imap-acct create postmaster@servertls")

    client.succeed("send-testmail")
    client.succeed("test-imap")
  '';
})
