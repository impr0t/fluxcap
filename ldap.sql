DECLARE
  l_ldap_host VARCHAR2(256) := 'city.canada.ab.ca';
  -- can resolve through dns.

  l_ldap_port VARCHAR2(256) := '389';
  -- default port of LDAP

  l_ldap_user VARCHAR2(256) := 'canada\citizen';
  -- domain login (i.e) DOMAIN\USERNAME

  l_ldap_passwd VARCHAR2(256) := &password.';'
  -- password if you please. This is going to prompt through SQLPLUS or Oracle SQL Developer.

  l_ldap_base VARCHAR2(256) := 'dc=city,dc=medicine-hat,dc=ab,dc=ca';
  -- Full distinguished name of the base you which to search.

  l_retval PLS_INTEGER;
  l_attr_name VARCHAR(256);
  l_session SYS.dbms_ldap.session;
  l_attrs SYS.dbms_ldap.string_collection;
  l_vals sys.dbms_ldap.string_collection;
  l_ber_element sys.dbms_ldap.ber_element;
  l_message SYS.dbms_ldap.message;
  l_entry SYS.dbms_ldap.message;

BEGIN
  SYS.dbms_ldap.use_exception := true;
  SYS.dbms_ldap.utf8_conversion := false;
  
  -- we need to create a session.
  l_session := SYS.dbms_ldap.init (hostname => l_ldap_host,
                                   portnum => l_ldap_port);

  -- we need to now bind our user to that session.
  l_retval := SYS.dbms_ldap.simple_bind_s(ld => l_session,
                                          dn => l_ldap_user,
                                          passwd => l_ldap_passwd);

  -- we need to populate the attributes collection
  -- these attributes will be what we get back in our search
  -- result.
  l_attrs(1) := 'givenname';         -- first name
  l_attrs(2) := 'sn';                -- last name
  l_attrs(3) := 'userprincipalname'; -- user id
  -- we need to build up our query.
  l_retval := SYS.dbms_ldap.search_s(ld => l_session,
                                     base => l_ldap_base,
                                     scope => sys.dbms_ldap.scope_subtree,
                                     filter => '(&(objectclass=USER)(memberof=<replace me WITH the full dn OF the GROUP>))',
                                     attrs => l_attrs,
                                     attronly => 0,
                                     res => l_message);

  -- if we get results, let's LOOP through them.
  IF sys.dbms_ldap.count_entries(ld=>l_session, msg=>l_message) > 0 THEN
    l_entry := sys.dbms_ldap.first_entry(ld=>l_session,
                                         msg=>l_message);

    WHILE l_entry IS NOT NULL
    LOOP
      sys.dbms_output.put_line('got: '
      || l_entry);
      l_attr_name := sys.dbms_ldap.first_attribute(ld => l_session,
                                                   ldapentry => l_entry,
                                                   ber_elem => l_ber_element);
      WHILE l_attr_name IS NOT NULL
      LOOP
        sys.dbms_output.put_line('got: '
        || l_attr_name);
        l_vals := sys.dbms_ldap.get_values(ld => l_session,
                                           ldapentry => l_entry,
                                           attr => l_attr_name);
        FOR i IN l_vals.first .. l_vals.last
        LOOP
          sys.dbms_output.put_line('Attribute_Name: '
          || l_attr_name
          || ' = '
          || substr(l_vals(i),1,200));
        END LOOP;
        l_attr_name := sys.dbms_ldap.next_attribute(ld => l_session,
                                                    ldapentry => l_entry,
                                                    ber_elem => l_ber_element);
      END LOOP;
      l_entry := sys.dbms_ldap.next_entry(ld => l_session,
                                          msg => l_entry);
    END LOOP;
  END IF;
  l_retval := sys.dbms_ldap.unbind_s(ld => l_session);
  -- close our session out.
EXCEPTION
WHEN sys.dbms_ldap.invalid_session THEN
  sys.dbms_output.put_line('The session provided is invalid.');
WHEN OTHERS THEN
  raise_application_error(-20001,'An error was encountered - '
  ||SQLCODE
  ||' -ERROR- '
  ||SQLERRM);
END;
