/**
 *
 * Redistribution and use in source and binary forms, with or without modification,
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 * - Neither the name of the Andrew Fawcett, nor the names of its contributors
 *      may be used to endorse or promote products derived from this software without
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 **/
@IsTest
private with sharing class di_PlatformCacheTest {

    static final String EXPECTED_PARTITION_NAME = 'diPartition';
    static final Cache.Visibility CACHE_VISIBILITY = Cache.Visibility.ALL;

    @IsTest
    private static void getInstanceShouldAlwaysReturnSamePlatformCacheInstance() {
        // Given
        di_PlatformCache cache1 = di_PlatformCache.getInstance();

        // When
        di_PlatformCache cache2 = di_PlatformCache.getInstance();

        // Then
        System.assertEquals(cache1, cache2);

    }

    @IsTest
    private static void givenPlatformCacheConfigThenCreate() {
        // Given

        // When
        di_Configurations__c config = di_PlatformCache.getConfig();

        // Then
        System.assertNotEquals(null, config);
    }

    @IsTest
    private static void givenStoringBindingIsTrueThenGet() {
        // Given/ When configuration is true
        makeData();

        //Then
        //  depending on the org, the cache partition may not be present.  
        //  If that is the case, then the isStoringBindingInPlatformCache() method
        //  will return false regardless what we setup in the makeData() method here 
        //  in the test class
        if ( di_PlatformCache.getPartition() == null ) {
            System.assert(!di_PlatformCache.isStoringBindingInPlatformCache());
        } else {
            System.assert(di_PlatformCache.isStoringBindingInPlatformCache());
        }
    }


    @IsTest
    private static void givenPartitionNameSetThenGetNonNull() {
        // Given/ When partition name is set
        makeData();
        //Then
        System.assertEquals(EXPECTED_PARTITION_NAME, di_PlatformCache.getPartitionName());

    }

    @IsTest
    private static void givenPartitionTTLSetThenGetSeconds() {
        // Given/ When partition name is set
        di_PlatformCache cache = di_PlatformCache.getInstance();
        //Then
        System.assertEquals(di_PlatformCache.NUM_OF_SECS_IN24HR, cache.getPartitionTTL());

    }

    @IsTest
    private static void givenNoDataInCachePartitionThenGetEmptyKeys() {
        // Given/ When partition name is set
        makeData();
        di_PlatformCache cache = di_PlatformCache.getInstance();
        //Then
        System.assertEquals(0, cache.getCacheKeyIndexMap().size());

    }

    @IsTest
    private static void givenDataInCachePartitionIsNotEnabledThenGetEmptyKeys() {
        // Given when not storing ( )
        makeData(false);
        di_PlatformCache cache = di_PlatformCache.getInstance();
        // create binding
        di_Binding binding = di_Binding.newInstance(
            di_Binding.BindingType.Apex,
            di_BindingTest.Bob.class.getName(), null, null, di_BindingTest.Bob.class.getName(), null);
        // When
        cache.addBindingToPlatformCache(binding);
        //Then
        System.assertEquals(0, cache.getCacheKeyIndexMap().size());

    }

    @IsTest
    private static void givenDataInCachePartitionIsEnabledThenGetEmptyKeys() {
        // Given when  storing ( )
        Integer expected=0;
        makeData(true);
        di_PlatformCache cache = di_PlatformCache.getInstance();
        // if there IS NO Partition created; let's not FAIL
        Cache.OrgPartition orgPartition = di_PlatformCache.getPartition();
        // if we have cache informaiton, then we expect 1
        if ( orgPartition != null ) {
            expected=1;
        }
        // create binding
        di_Binding binding = di_Binding.newInstance(
            di_Binding.BindingType.Apex,
            di_BindingTest.Bob.class.getName(), null, null, di_BindingTest.Bob.class.getName(), null);
        // When
        cache.addBindingToPlatformCache(binding);
        //Then
        System.assertEquals(expected, cache.getCacheKeyIndexMap().size());

    }

    @IsTest
    private static void givenCachedBindingsClearThenGetEmpty() {
        // Given
        makeData(true);

        // When
        di_PlatformCache.clearCachedBindings();
        Set<String> keys = di_PlatformCache.getPartitionKeys();
        //Then
        System.assertEquals(true,keys == null || keys.size()==0);

    }

    @IsTest
    private static void givenBindingsInCacheThenRetrieveBindings() {
        // Given
        String developerName = 'developerName';
        SObjectType bindingSObjectType = Account.SObjectType;
        makeData(true);
        di_PlatformCache platformCache = di_PlatformCache.getInstance();
        Cache.OrgPartition orgPartition = di_PlatformCache.getPartition();

        // Create some test bindings
        Account account1 = new Account(Name = 'Account 1');
        Account account2 = new Account(Name = 'Account 2');
        Account account3 = new Account(Name = 'Account 3');
        di_Binding binding1 = di_Binding.newInstance(
                di_Binding.BindingType.Apex,
                'developerName', Account.SObjectType, null, account1, null);
        di_Binding binding2 = di_Binding.newInstance(
                di_Binding.BindingType.Apex,
                'developerName', Account.SObjectType, null, account2, null);
        di_Binding binding3 = di_Binding.newInstance(
                di_Binding.BindingType.Apex,
                'differentName', Account.SObjectType, null, account3, null);

        // if cache partition exists, add bindings to cache
        // if not, don't - at least the test will pass, but we will miss some coverage
        if (orgPartition != null) {
            List<di_Binding> bindings = new List<di_Binding>{ binding1, binding2 };
            List<di_Binding> otherBindings = new List<di_Binding>{ binding3 };
            orgPartition.put('accountdevelopername', bindings, 300, CACHE_VISIBILITY, false);
            orgPartition.put('accountdifferentname', otherBindings, 300, CACHE_VISIBILITY, false);
            Map<String, Map<Schema.SObjectType, Set<String>>> bindingKeyIndex = new Map<String, Map<Schema.SObjectType, Set<String>>>();
            bindingKeyIndex.put('developername', new Map<Schema.SObjectType, Set<String>> { Account.SObjectType => new Set<String> { 'accountdevelopername' } });
            bindingKeyIndex.put('differentname', new Map<Schema.SObjectType, Set<String>> { Account.SObjectType => new Set<String> { 'accountdifferentname' } });
            orgPartition.put('bindingKeyIndex', bindingKeyIndex, 300, CACHE_VISIBILITY, false);
        }

        // When
        List<di_Binding> retrievedBindings = platformCache.retrieveBindings(developerName, bindingSObjectType);

        // Then
        if (orgPartition != null) {
            System.assertEquals(2, retrievedBindings.size());
            System.assertEquals(binding1, retrievedBindings.get(0));
            System.assertEquals(binding2, retrievedBindings.get(1));
        } else {
            System.assertEquals(0, retrievedBindings.size());
        }
    }

    @IsTest
    private static void givenInvalidDeveloperNameThenGetEmptyKeys() {
        // Given
        makeData(true);
        di_PlatformCache cache = di_PlatformCache.getInstance();
        // when
        List<di_Binding>  binding = cache.retrieveBindings(null,Account.SObjectType);
        //Then
        System.assertEquals(0,binding.size());
    }

    @IsTest
    private static void givenInvalidSObjectTypeThenGetEmptyKeys() {
        // Given
        makeData(true);
        di_PlatformCache cache = di_PlatformCache.getInstance();
        // when
        List<di_Binding>  binding = cache.retrieveBindings('value',null);
        //Then
        System.assertEquals(0,binding.size());
    }

    @IsTest
    private static void givenCacheMapAddedThenGetKeys() {
        // Given
        di_PlatformCache cache = di_PlatformCache.getInstance();
        // When
        Cache.OrgPartition orgPartition = di_PlatformCache.getPartition();
        //Then
        System.assertEquals(orgPartition != null,cache.pushCacheKeyIndexMapToCache());
    }

    @IsTest
    private static void givenLogMethodThenGetKeys() {
        // Given
        di_PlatformCache.DEBUGGING = true;
        // When
        //Then
        System.assertEquals(true,di_PlatformCache.log('test'));
        System.assertEquals(true,di_PlatformCache.log(new NullPointerException()));
    }

    @IsTest
    private static void givenValidBindingThenAddBinding() {
        // Given
        di_PlatformCache cache = di_PlatformCache.getInstance();
        // create binding
        di_Binding binding = di_Binding.newInstance(
            di_Binding.BindingType.Apex,
            di_BindingTest.Bob.class.getName(), null, null, di_BindingTest.Bob.class.getName(), null);
        String workingDeveloperName = binding.DeveloperName.toLowerCase().trim();

        // When
        cache.addBindingToKeyIndex(binding);
        // Then
        System.assertEquals(1, cache.getCacheKeyIndexMap().size());
        System.assertNotEquals(null,cache.getCacheKeyIndexMap().get(workingDeveloperName));
    }

    //
    @IsTest
    private static void givenValidTSTypeAndNameThenHash() {
        // Given
        di_PlatformCache cache = di_PlatformCache.getInstance();

        // When
        String hash= cache.constructKeyName(Account.SObjectType,'test');

        // Then
        System.assertEquals(true, hash != null);

    }
    //
    @IsTest
    private static void givenKeyIndexNameThenGetKey() {
        // Given
        di_PlatformCache cache = di_PlatformCache.getInstance();

        // When
        String keyIndexName = cache.getKeyIndexName();

        // Then
        System.assertEquals(di_PlatformCache.BINDING_KEY, keyIndexName);

    }

    @IsTest
    private static void givenValidSTypeAndNameThenHash() {
        // Given
        di_PlatformCache cache = di_PlatformCache.getInstance();

        // When
        String hash= cache.constructKeyName(Account.SObjectType,'test');

        // Then
        System.assertNotEquals(null, hash);

    }

    @IsTest
    private static void givenDevNameAndSTypeThenGetHashAndKey() {
        // Given
        di_PlatformCache cache = di_PlatformCache.getInstance();

        // When
        String key = cache.getKeyName('test',Account.SObjectType);
        String hash = cache.constructKeyName(Account.SObjectType,'test');

        // Then
        System.assertEquals(hash, key);

    }

    @IsTest
    private static void givenReadOnlyAccessThenGetInstance() {
        // Given
        User ruser = di_PlatformCacheTest.setROTestUser();
        System.runAs(ruser) {
            // When
            di_Configurations__c config = di_PlatformCache.getConfig();

            // Then
            System.assertNotEquals(null, config);
            System.assert(!config.UsePlatformCacheToStoreBindings__c);
            System.assertEquals(null, config.OrgCachePartitionName__c);
        }
    }

    @IsTest
    private static void givenANewConfigSettingThenGetThatInstance() {
        // Given
        User ruser = di_PlatformCacheTest.setROTestUser();
        final String PARTITION = 'test';
        di_Configurations__c usrConfig = new di_Configurations__c();
        usrConfig.SetupOwnerId = ruser.Id;
        usrConfig.UsePlatformCacheToStoreBindings__c = true;
        usrConfig.OrgCachePartitionName__c = PARTITION;
        insert usrConfig;
       
        System.runAs(ruser) {
            // When
            di_Configurations__c config = di_PlatformCache.getConfig();

            // Then
            System.assertNotEquals(null, config);
            System.assert(config.UsePlatformCacheToStoreBindings__c);
            System.assertEquals(PARTITION, config.OrgCachePartitionName__c);
        }
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Private Helper
    ///////////////////////////////////////////////////////////////////////////////

    private static void makeData(){
        makeData(true);
    }

    private static void makeData(Boolean isStoring){
        di_Configurations__c setting = new di_Configurations__c(SetupOwnerId = UserInfo.getUserId());

        setting.OrgCachePartitionName__c = EXPECTED_PARTITION_NAME;
        setting.UsePlatformCacheToStoreBindings__c = isStoring;
        insert setting;
    }

    /**
     * Creates a read-only user
     */
    private static User setROTestUser() {
		Profile prof;
        try {
            prof = [SELECT Id FROM Profile WHERE Name = 'Read Only'];
        } catch (QueryException ex) {
            if (ex.getMessage().contains('List has no rows for assignment to SObject')) {
                // #315 If the "Read Only" Profile is absent, then assume it's a Spring '21 org and see if there's a
                // "Minimum Access - Salesforce" Profile we can use instead.
                prof = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce'];
            }
        }

        User newUser = new User(Alias = 'readonly',
                                Email='standarduser@mytest.com',
                                EmailEncodingKey='UTF-8',
                                LastName='TestingReadOnly',
                                LanguageLocaleKey='en_US',
                                LocaleSidKey='en_US',
                                ProfileId = prof.Id,
                                TimeZoneSidKey='America/Los_Angeles',
                                Username='readonly@mytest.com');

        insert newUser;
 
        return newUser;
    }
}
