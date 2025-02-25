// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;

isolated  function getSearchElement(SearchElement[] searchElements) returns string{
    string searchElementInPayloadBody = EMPTY_STRING;
    foreach SearchElement element in searchElements {
        searchElementInPayloadBody += getXMLSearchElement(element);
    }
    return searchElementInPayloadBody;
}

isolated function getMultiValues(SearchElement element) returns string {
    string multiSelectValues  = EMPTY_STRING;
    if (element?.multiSelectValues is RecordRef[]) {
        foreach RecordRef reference in  <RecordRef[]>element?.multiSelectValues {
            multiSelectValues += string `<urn1:searchValue internalId="${reference.internalId}"  xsi:type="urn1:RecordRef"/> `;
        }
    }
    return multiSelectValues;
}

isolated  function getXMLSearchElement(SearchElement element) returns string {
    if (element.searchType == SEARCH_MULTI_SELECT_FIELD) {
        return string `<ns1:${element.fieldName} ${getSearchElementOperator(element).toString()} xsi:type="urn1:SearchMultiSelectField">
          ${getMultiValues(element)}
         </ns1:${element.fieldName}>`;
    }
    return string `<ns1:${element.fieldName} 
        ${getSearchElementOperator(element).toString()}
        xsi:type="urn1:${element.searchType.toString()}">
        <urn1:searchValue>${element.value1}</urn1:searchValue>
        ${getOptionalSearchValue(element).toString()}
        </ns1:${element.fieldName}>`;
}

isolated function getSearchElementOperator(SearchElement element) returns string? {
    if (element.searchType != SEARCH_BOOLEAN_FIELD) {
        return string `operator="${element.operator.toString()}"`;
    } 
}

isolated  function getOptionalSearchValue(SearchElement element) returns string? {
    if (element?.value2 is string) {
        if (element.searchType == SEARCH_BOOLEAN_FIELD) {
            return;
        } else if (element.searchType == SEARCH_ENUM_MULTI_SELECT_FIELD) {
            string multiValues =  string `<urn1:searchValue>${element?.value2.toString()}</urn1:searchValue>`;
            string[] moreMultiValues = let var valuesArray = element?.multiValues in valuesArray is string[] ? valuesArray : [];
            if(moreMultiValues.length() > 0) {
                foreach string value in moreMultiValues {
                    multiValues += string `<urn1:searchValue>${value}</urn1:searchValue>`;
                }
            }
            return multiValues;
        } else {
            return string `<urn1:searchValue2>${element?.value2.toString()}</urn1:searchValue2>`;
        }
    }
}

isolated function getNextPageRequestElement(int pageIndex, string searchId) returns string {
    return string `<soapenv:Body><urn:searchMoreWithId>
            <searchId>${searchId}</searchId>
            <pageIndex>${pageIndex}</pageIndex>
        </urn:searchMoreWithId></soapenv:Body></soapenv:Envelope>`;
}

isolated function buildSearchMoreWithIdPayload(ConnectionConfig config, int pageIndex, string searchId) returns 
                                                xml|error {
    string requestHeader = check buildXMLPayloadHeader(config);
    string requestBody = getNextPageRequestElement(pageIndex, searchId);
    return check getSoapPayload(requestHeader, requestBody); 
}

isolated function buildSavedSearchByIDPayload(ConnectionConfig config, string savedSearchID, string advancedSearchType) returns xml|error {
    string requestHeader = check buildXMLPayloadHeader(config);
    string requestBody = check getSaveSearchByIDRequestBody(savedSearchID, advancedSearchType);
    return check getSoapPayload(requestHeader, requestBody);
}

isolated function getSaveSearchByIDRequestBody(string savedSearchID, string advancedSearchType) returns string|error {
    return string `<soapenv:Body><urn:search xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <urn:searchRecord xmlns:q1="${check getSearchAdvancedNS(advancedSearchType)}"
        xsi:type="q1:${advancedSearchType}" savedSearchId="${savedSearchID}" />
        </urn:search></soapenv:Body></soapenv:Envelope>`;
}

isolated function getSavedSearchResult(http:Response response, http:Client httpClient, ConnectionConfig config) returns 
                                       stream<SearchResult, error?>|error {
    SavedSearchResult resultStatus = check getXMLRecordListFromSavedSearchResult(response);
    SavedSearchStream instance = check new (httpClient,resultStatus,config);
    stream<SearchResult, error?> finalStream = new (instance);
    return finalStream;
}

isolated function getSavedSearchNextPageResult(http:Response response) returns @tainted record {|json[] savedSearchRows; SavedSearchResult status;|}|error {
    SavedSearchResult resultStatus = check getXMLRecordListFromSavedSearchResult(response);
    return {savedSearchRows : resultStatus.recordList, status: resultStatus};
}

isolated function getSearchAdvancedNS(string searchAdvanceType) returns string|error {
    match searchAdvanceType {
        CALENDAR_EVENT_SEARCH_ADVANCED => {
            return SCHEDULING_2020_2;
        }
        TASK_SEARCH_ADVANCED => {
            return SCHEDULING_2020_2;
        }
        PHONE_CALL_SEARCH_ADVANCED => {
            return SCHEDULING_2020_2;
        }
        FILE_SEARCH_ADVANCED => {
            return FILE_CABINET_2020_2;
        }
        FOLDER_SEARCH_ADVANCED => {
            return FILE_CABINET_2020_2;
        }
        NOTE_SEARCH_ADVANCED => {
            return COMMUNICATION_2020_2;
        }
        MESSAGE_SEARCH_ADVANCED => {
            return COMMUNICATION_2020_2;
        }
        ITEM_SEARCH_ADVANCED => {
            return ACCOUNTING_2020_2;
        }
        ACCOUNT_SEARCH_ADVANCED => {
            return ACCOUNTING_2020_2;
        }
        BIN_SEARCH_ADVANCED => {
            return ACCOUNTING_2020_2;
        }
        CLASSIFICATION_SEARCH_ADVANCED => {
            return ACCOUNTING_2020_2;
        }
        DEPARTMENT_SEARCH_ADVANCED => {
            return ACCOUNTING_2020_2;
        }
        LOCATION_SEARCH_ADVANCED => {
            return ACCOUNTING_2020_2;
        }
        GIFT_CERTIFICATE_SEARCH_ADVANCED => {
            return ACCOUNTING_2020_2;
        }
        SALES_TAX_ITEM_SEARCH_ADVANCED => {
            return ACCOUNTING_2020_2;
        }
        SUBSIDIARY_SEARCH_ADVANCED => {
            return ACCOUNTING_2020_2;
        }
        EMPLOYEE_SEARCH_ADVANCED => {
            return EMPLOYEES_2020_2;
        }
        CAMPAIGN_SEARCH_ADVANCED => {
            return MARKETING_2020_2;
        }
        PROMOTION_CODE_SEARCH_ADVANCED => {
            return MARKETING_2020_2;
        }
        CONTACT_SEARCH_ADVANCED => {
            return RELATIONSHIPS_2020_2;
        }
        CUSTOMER_SEARCH_ADVANCED => {
            return RELATIONSHIPS_2020_2;
        }
        PARTNER_SEARCH_ADVANCED => {
            return RELATIONSHIPS_2020_2;
        }
        VENDOR_SEARCH_ADVANCED => {
            return RELATIONSHIPS_2020_2;
        }
        ENTITY_GROUP_SEARCH_ADVANCED => {
            return RELATIONSHIPS_2020_2;
        }
        JOB_SEARCH_ADVANCED => {
            return RELATIONSHIPS_2020_2;
        }
        SITE_CATEGORY_SEARCH_ADVANCED => {
            return WEBSITE_2020_2;
        }
        SUPPORT_CASE_SEARCH_ADVANCED => {
            return SUPPORT_2020_2;
        }
        SOLUTION_SEARCH_ADVANCED => {
            return SUPPORT_2020_2;
        }
        TOPIC_SEARCH_ADVANCED => {
            return SUPPORT_2020_2;
        }
        ISSUE_SEARCH_ADVANCED => {
            return SUPPORT_2020_2;
        }
        CUSTOM_RECORD_SEARCH_ADVANCED => {
            return CUSTOMIZATION_2020_2;
        }
        TIME_BILL_SEARCH_ADVANCED => {
            return EMPLOYEES_2020_2;
        }
        BUDGET_SEARCH_ADVANCED => {
            return FINANCIAL_2020_2;
        }
        ACCOUNTING_TRANSACTION_SEARCH_ADVANCED => {
            return SALES_2020_2;
        }
        OPPORTUNITY_SEARCH_ADVANCED => {
            return SALES_2020_2;
        }
        TRANSACTION_SEARCH_ADVANCED => {
            return SALES_2020_2;
        }
        _ => {
            fail error(NO_TYPE_MATCHED);
        }
    }
}
