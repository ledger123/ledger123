#=====================================================================
# SQL-Ledger ERP
# Copyright (c) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#=====================================================================
#
# login frontend
#
#=====================================================================


use DBI;
use SL::User;
use SL::Form;


$form = new Form;


$locale = new Locale $language, "login";
$form->{charset} = $locale->{charset};

# customization
if (-f "$form->{path}/custom_$form->{script}") {
  eval { require "$form->{path}/custom_$form->{script}"; };
  $form->error($@) if ($@);
}

# per login customization
if (-f "$form->{path}/$form->{login}_$form->{script}") {
  eval { require "$form->{path}/$form->{login}_$form->{script}"; };
  $form->error($@) if ($@);
}

# window title bar
$form->{titlebar} = "SQL-Ledger";

if ($form->{action}) {
  &{ $locale->findsub($form->{action}) };
} else {
  &login_screen;
}


1;


sub login_screen {

  $form->{stylesheet} = "sql-ledger.css";
  $form->{favicon} = "sql-ledger.ico";

  $form->header;

  if ($form->{login}) {
   $sf = qq|function sf() { document.forms[0].password.focus(); }|;
  } else {
   $sf = qq|function sf() { document.forms[0].login.focus(); }|;
  }

  print qq|
<script language="javascript" type="text/javascript">
<!--
var agt = navigator.userAgent.toLowerCase();
var is_major = parseInt(navigator.appVersion);
var is_nav = ((agt.indexOf('mozilla') != -1) && (agt.indexOf('spoofer') == -1)
           && (agt.indexOf('compatible') == -1) && (agt.indexOf('opera') == -1)
	   && (agt.indexOf('webtv') == -1));
var is_nav4lo = (is_nav && (is_major <= 4));

function jsp() {
  if (is_nav4lo)
    document.forms[0].js.value = ""
  else
    document.forms[0].js.value = "1"
}
$sf
// End -->
</script>
|;

  print qq|

<body class=login onload="jsp(); sf()">

<pre>

</pre>

<center>
<table class=login border=3 cellpadding=20>
  <tr>
    <td class=login align=center><a href="http://www.sql-ledger.com" target=_blank><img src=$images/sql-ledger.gif border=0></a>
<h1 class=login align=center>|.$locale->text('Version').qq| $form->{version}</h1>

<p>

      <form method=post action=$form->{script}>

      <table width=100%>
	<tr>
	  <td align=center>
	    <table>
	      <tr>
		<th align=right>|.$locale->text('Name').qq|</th>
		<td><input class=login name=login size=30></td>
	      </tr> 
	      <tr>
		<th align=right>|.$locale->text('Password').qq|</th>
		<td><input class=login type=password name=password size=30></td>
	      </tr>
	    </table>

	    <br>
	    <input type=submit name=action value="|.$locale->text('Login').qq|">
	  </td>
	</tr>
      </table>
|;

    $form->hide_form(qw(js path));

  print qq|
      </form>

    </td>
  </tr>
</table>
  
</body>
</html>
|;

}


sub selectdataset {
  my ($login) = @_;
  
  if (-f "css/sql-ledger.css") {
    $form->{stylesheet} = "sql-ledger.css";
  }
  if (-f sql-ledger.ico) {
    $form->{favicon} = "sql-ledger.ico";
  }

  delete $self->{sessioncookie};
  $form->header(1);

  print qq|
<body class=login onload="document.forms[0].password.focus()" />

<pre>

</pre>

<center>
<table class=login border=3 cellpadding=20>
  <tr>
    <td class=login align=center><a href="http://www.sql-ledger.com" target=_blank><img src=$images/sql-ledger.gif border=0></a>
<h1 class=login align=center>|.$locale->text('Version').qq| $form->{version}</h1>

<p>

<form method=post action=$form->{script}>

<input type=hidden name=beenthere value=1>

      <table width=100%>
	<tr>
	  <td align=center>
	    <table>
	      <tr>
		<th align=right>|.$locale->text('Name').qq|</th>
		<td>$form->{login}</td>
	      </tr> 
	      <tr>
		<th align=right>|.$locale->text('Password').qq|</th>
		<td><input class=login type=password name=password size=30 value=$form->{password}></td>
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Company').qq|</th>
		<td>|;
		
		$form->hide_form(qw(js path));
	      
		$checked = "checked";
		for (sort { $login{$a} cmp $login{$b} } keys %{ $login }) {
		  print qq|
		  <br><input class=login type=radio name=login value=$_ $checked>$login->{$_}
		  |;
		  $checked = "";
		}

		print qq|
		  </td>
	      </tr>
	    </table>
	    <br>
	    <input type=submit name=action value="|.$locale->text('Login').qq|">
	  </td>
	</tr>
      </table>

</form>

    </td>
  </tr>
</table>
  
</body>
</html>
|;


}


sub login {

  $form->{stylesheet} = "sql-ledger.css";
  $form->{favicon} = "sql-ledger.ico";
  
  $form->error($locale->text('You did not enter a name!')) unless ($form->{login});

  if (! $form->{beenthere}) {
    open(FH, "$memberfile") or $form->error("$memberfile : $!");
    @members = <FH>;
    close(FH);

    while (@members) {
      $_ = shift @members;
      if (/^\[(.*\@.*)\]/) {
	$login = $1;
	if ($login =~ /^$form->{login}(\@|$)/) {
	  ($name, $dbname) = split /\@/, $login;
	  $login{$login} = $dbname;

	  do {
	    if (/^company=/) {
	      ($null, $company) = split /=/, $_, 2;
	      chop $company;
	      $login{$login} = $company if $company;
	    }
	    $_ = shift @members;
	  } until /^\s+$/;
	}
      }
    }

    if (keys %login > 1) {
      &selectdataset(\%login);
      exit;
    } else {
      if ($form->{login} !~ /\@/) {
	$form->{login} .= "\@$dbname";
      }
    }
  }

  $user = new User $memberfile, $form->{login};

  # if we get an error back, bale out
  if (($errno = $user->login(\%$form, $userspath)) <= -1) {

    $errno *= -1;
    $err[1] = $locale->text('Incorrect Username!');
    $err[2] = $locale->text('Incorrect Password!');
    $err[3] = $locale->text('Incorrect Dataset version!');
    $err[4] = $locale->text('Dataset is newer than version!');


    if ($errno == 1 && $form->{admin}) {
      $err[1] = $locale->text('admin does not exist!');
    }

    if ($errno == 5) {
      if (-f "$userspath/$user->{dbname}.LCK") {
	if (-s "$userspath/$user->{dbname}.LCK") {
	  open(FH, "$userspath/$user->{dbname}.LCK");
	  $msg = <FH>;
	  close(FH);
	  if ($form->{admin}) {
	    $form->info($msg);
	  } else {
	    $form->error($msg);
	  }
	} else {
	  $msg = $locale->text('Dataset locked!');
	  if ($form->{admin}) {
	    $form->info($msg);
	  } else {
	    $form->error($msg);
	  }
	}

      } else {
      
	# upgrade dataset and log in again
	open FH, ">$userspath/$user->{dbname}.LCK" or $form->error($!);

	for (qw(dbname dbhost dbport dbdriver dbuser dbpasswd)) { $form->{$_} = $user->{$_} }

	$form->info($locale->text('Upgrading to Version')." $form->{version} ... ");

	# required for Oracle
	$form->{dbdefault} = $sid;

	$user->dbupdate(\%$form);

	# remove lock file
	unlink "$userspath/$user->{dbname}.LCK";
	
      }

      $form->info("<p><a href=menu.pl?login=$form->{login}&path=$form->{path}&action=display&main=company_logo&js=$form->{js}&password=$form->{password}>".$locale->text('Continue')."</a>");
      
      exit;
      
    }
    
    $form->error($err[$errno]);
    
  }

  for (qw(dbconnect dbhost dbport dbname dbuser dbpasswd)) { $myconfig{$_} = $user->{$_} }

  # remove stale locks
  $form->remove_locks(\%myconfig);

  $form->{timeout} = $user->{timeout};
  $form->{sessioncookie} = $user->{sessioncookie};

  # made it this far, setup callback for the menu
  $form->{callback} = "menu.pl?action=display";
  for (qw(login path password js sessioncookie)) { $form->{callback} .= "&$_=$form->{$_}" }
  
  # check for recurring transactions
  if ($user->{acs} !~ /Recurring Transactions/) {
    if ($user->check_recurring(\%$form)) {
      $form->{callback} .= "&main=recurring_transactions";
    } else {
      $form->{callback} .= "&main=company_logo";
    }
  } else {
    $form->{callback} .= "&main=company_logo";
  }

  $form->redirect;
  
}



sub logout {

  require "$userspath/$form->{login}.conf";
  $myconfig{dbpasswd} = unpack 'u', $myconfig{dbpasswd};

  $form->{callback} = "$form->{script}?path=$form->{path}&endsession=1";
  User->logout(\%myconfig, \%$form);

  $form->redirect;

}


