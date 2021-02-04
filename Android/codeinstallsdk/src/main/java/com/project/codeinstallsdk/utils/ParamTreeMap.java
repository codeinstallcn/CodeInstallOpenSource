package com.project.codeinstallsdk.utils;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.Collection;
import java.util.Comparator;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

public class ParamTreeMap {
    public static Map<String, String> sortMap = new Map() {
        @Override
        public int size() {
            return 0;
        }

        @Override
        public boolean isEmpty() {
            return false;
        }

        @Override
        public boolean containsKey(@Nullable Object o) {
            return false;
        }

        @Override
        public boolean containsValue(@Nullable Object o) {
            return false;
        }

        @Nullable
        @Override
        public Object get(@Nullable Object o) {
            return null;
        }

        @Nullable
        @Override
        public Object put(Object o, Object o2) {
            return null;
        }

        @Nullable
        @Override
        public Object remove(@Nullable Object o) {
            return null;
        }

        @Override
        public void putAll(@NonNull Map map) {

        }

        @Override
        public void clear() {

        }

        @NonNull
        @Override
        public Set keySet() {
            return null;
        }

        @NonNull
        @Override
        public Collection values() {
            return null;
        }

        @NonNull
        @Override
        public Set<Entry> entrySet() {
            return null;
        }

        @Override
        public boolean equals(@Nullable Object o) {
            return false;
        }

        @Override
        public int hashCode() {
            return 0;
        }
    };

    public static Map<String, String> getSortMap() {
        sortMap.clear();
        return sortMap;
    }
}
