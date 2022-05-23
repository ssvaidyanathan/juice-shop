/*
 * Copyright (c) 2014-2022 Bjoern Kimminich & the OWASP Juice Shop contributors.
 * SPDX-License-Identifier: MIT
 */

export const environment = {
  production: true,
  //hostServer: 'http://localhost:3000',
  hostServer: '${process.env.API_ENDPOINT}${process.env.BASEPATH}',
  apikey: '${process.env.APIKEY}',
  socketServer: '.'
}